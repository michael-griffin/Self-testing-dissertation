function [position, RT, answer] = slideforJOL(window, rect, endPoints, message, wordpair, varargin)
%SLIDESCALE This funtion draws a slide scale on a PSYCHTOOLOX 3 screen and returns the
% position of the slider spaced between -100 and 100 as well as the rection time and if an answer was given.
%
%   Usage: [position, secs] = slideScale(window, question, center, rect, endPoints, varargin)
%   Mandatory input:
%    window         -> Pointer to the window.
%    question       -> Text string containing the question.
%    rect           -> Double contatining the screen size.
%                      Obtained with [myScreen, rect] = Screen('OpenWindow', 0);
%    endPoints      -> Cell containg the two text string of the left and right
%                      end of the scala. Exampe: endPoints = {'left, 'right'};
%
%   Varargin:
%    'linelength'     -> An integer specifying the lengths of the ticks in
%                        pixels. The default is 10.
%    'width'          -> An integer specifying the width of the scala line in
%                        pixels. The default is 3.
%    'range'          -> An integer specifying the type of range. If 1,
%                        then the range is from -100 to 100. If 2, then the
%                        range is from 0 to 100. Default is 2.
%    'startposition'  -> Choose 'right', 'left' or 'center' start position.
%                        Default is center.
%    'scalalength'    -> Double value between 0 and 1 for the length of the
%                        scale. The default is 0.9.
%    'scalaposition'  -> Double value between 0 and 1 for the position of the
%                        scale. 0 is top and 1 is bottom. Default is 0.8.
%    'device'         -> A string specifying the response device. Either 'mouse'
%                        or 'keyboard'. The default is 'mouse'.
%    'responsekey'    -> String containing name of the key from the keyboard to log the
%                        response. The default is 'return'.
%    'slidecolor'     -> Vector for the color value of the slider [r g b]
%                        from 0 to 255. The default is red [255 0 0].
%    'scalacolor'     -> Vector for the color value of the scale [r g b]
%                        from 0 to 255.The default is black [0 0 0].
%    'aborttime'      -> Double specifying the time in seconds after which
%                        the function should be aborted. In this case no
%                        answer is saved. The default is 99 secs.
%    'displayposition'-> If true, the position of the slider is displayed.
%                        The default is false.
%
%   Output:
%    'position'      -> Deviation from zero in percentage,
%                       with -100 <= position <= 100 to indicate left-sided
%                       and right-sided deviation.
%    'RT'            -> Reaction time in milliseconds.
%    'answer'        -> If 0, no answer has been given. Otherwise this
%                       variable is 1.
%
%   Author: Joern Alexander Quent
%   e-mail: alexander.quent@rub.de
%   Version history:
%                    1.0 - 4. January 2016 - First draft
%                    1.1 - 18. Feburary 2016 - Added abort time and option to
%                    choose between mouse and key board
%                    1.2 - 5. October 2016 - End points will be aligned to end
%                    ticks
%                    1.3 - 06/01/2017 - Added the possibility to display an
%                    image
%                    1.4 - 5. May 2017 - Added the possibility to choose a
%                    start position
%                    1.5 - 7. November 2017 - Added the possibility to display
%                    the position of the slider under the scale.
%                    1.6 - 27. November 2017 - The function now waits until
%                    all keys are released before exiting.
%                    1.7 - 28. November 2017 - More than one screen
%                    supported now.
%                    1.8 - 29. November 2017 - Fixed issue that mouse is
%                    not properly in windowed mode.
%                    1.9 - 7. December 2017 - If an image is drawn, the
%                    corresponding texture is deleted at the end.
%                    1.10 - 28. December 2017 - Added the possibility to
%                    choose the type of range (0 to 100 or -100 to 100).
%% Parse input arguments
% Default values
center        = round([rect(3) rect(4)]/2);
lineLength    = 10;
width         = 3;
scalaLength   = 0.9;
scalaPosition = 0.8;
sliderColor    = [255 0 0];
scaleColor    = [0 0 0];
device        = 'mouse';
aborttime     = 99;
responseKey   = KbName('return');
GetMouseIndices;
drawImage     = 0;
startPosition = 'center';
displayPos    = false;
rangeType     = 2;

i = 1;
while(i<=length(varargin))
    switch lower(varargin{i})
        case 'linelength'
            i             = i + 1;
            lineLength    = varargin{i};
            i             = i + 1;
        case 'width'
            i             = i + 1;
            width         = varargin{i};
            i             = i + 1;
        case 'range'
            i             = i + 1;
            rangeType     = varargin{i};
            i             = i + 1;
        case 'startposition'
            i             = i + 1;
            startPosition = varargin{i};
            i             = i + 1;
        case 'scalalength'
            i             = i + 1;
            scalaLength   = varargin{i};
            i             = i + 1;
        case 'scalaposition'
            i             = i + 1;
            scalaPosition = varargin{i};
            i             = i + 1;
        case 'device'
            i             = i + 1;
            device = varargin{i};
            i             = i + 1;
        case 'responsekey'
            i             = i + 1;
            responseKey   = KbName(varargin{i});
            i             = i + 1;
        case 'slidecolor'
            i             = i + 1;
            sliderColor    = varargin{i};
            i             = i + 1;
        case 'scalacolor'
            i             = i + 1;
            scaleColor    = varargin{i};
            i             = i + 1;
        case 'aborttime'
            i             = i + 1;
            aborttime     = varargin{i};
            i             = i + 1;
        case 'displayposition'
            i             = i + 1;
            displayPos    = varargin{i};
            i             = i + 1;
    end
end

% Sets the default key depending on choosen device
if strcmp(device, 'mouse')
    responseKey = 1; % X mouse button
end

%% Checking number of screens and parsing size of the global screen
screens       = Screen('Screens');
if length(screens) > 1 % Checks for the number of screens
    screenNum        = 1;
else
    screenNum        = 0;
end
globalRect          = Screen('Rect', screenNum);

%% Coordinates of scale lines and text bounds
if strcmp(startPosition, 'right')
    x = globalRect(3)*scalaLength;
elseif strcmp(startPosition, 'center')
    x = globalRect(3)/2;
elseif strcmp(startPosition, 'left')
    x = globalRect(3)*(1-scalaLength);
else
    error('Only right, center and left are possible start positions');
end
SetMouse(round(x), round(rect(4)*scalaPosition), window, 1);
midTick    = [center(1) rect(4)*scalaPosition - lineLength - 2 center(1) rect(4)*scalaPosition  + lineLength + 2];
leftTick   = [rect(3)*(1-scalaLength) rect(4)*scalaPosition - lineLength rect(3)*(1-scalaLength) rect(4)*scalaPosition  + lineLength];
rightTick  = [rect(3)*scalaLength rect(4)*scalaPosition - lineLength rect(3)*scalaLength rect(4)*scalaPosition  + lineLength];
horzLine   = [rect(3)*scalaLength rect(4)*scalaPosition rect(3)*(1-scalaLength) rect(4)*scalaPosition];
textBounds = [Screen('TextBounds', window, endPoints{1}); Screen('TextBounds', window, endPoints{2})];

%Messy, added fromt the experiment. Need to build the display into this
%function, otherwise JUST displays slide rule. From the experiment. Need this to properly set up message
% textFont = 'Arial';
% textSize = 34;
wordcolor = [0,0,0];
textSize = 34;
instructSize = 22;
ndash = char(8211);
xPos = rect(3)/2;
yPos = rect(4)/2;
% Screen('TextFont', window, textFont);
% Screen('TextSize', window, textSize);
msgbound = 'WWWWWWWWW';
[bounds, bounds2] = Screen('TextBounds', window, msgbound, 50, 50);
xbuffer = round(bounds(3)/2); %minimum space off center where the word should be presented.
%xbound = bounds(3);
ybuffer = round(bounds(4)/4); %y adjust a little unusual WriteCentered. Should work.
%ybound = bounds(4);
yadjust = 100;

% Calculate the range of the scale, which will be need to calculate the
% position
scaleRange        = round(rect(3)*(1-scalaLength)):round(rect(3)*scalaLength); % Calculates the range of the scale
scaleRangeShifted = round((scaleRange)-mean(scaleRange));                      % Shift the range of scale so it is symmetrical around zero

%% Loop for scale loop
t0                         = GetSecs;
answer                     = 0;
while answer == 0
    [x,y,buttons,focus,valuators,valinfo] = GetMouse(window, 1);
    if x > rect(3)*scalaLength
        x = rect(3)*scalaLength;
    elseif x < rect(3)*(1-scalaLength)
        x = rect(3)*(1-scalaLength);
    end
    

    
    Screen('TextSize', window, instructSize);
    % Drawing the end points of the scala as text
    DrawFormattedText(window, endPoints{1}, leftTick(1, 1) - textBounds(1, 3)/2,  rect(4)*scalaPosition+40, [],[],[],[],[],[],[]); % Left point
    DrawFormattedText(window, endPoints{2}, rightTick(1, 1) - textBounds(2, 3)/2,  rect(4)*scalaPosition+40, [],[],[],[],[],[],[]); % Right point
    
    % Drawing the scala
    Screen('DrawLine', window, scaleColor, midTick(1), midTick(2), midTick(3), midTick(4), width);         % Mid tick
    Screen('DrawLine', window, scaleColor, leftTick(1), leftTick(2), leftTick(3), leftTick(4), width);     % Left tick
    Screen('DrawLine', window, scaleColor, rightTick(1), rightTick(2), rightTick(3), rightTick(4), width); % Right tick
    Screen('DrawLine', window, scaleColor, horzLine(1), horzLine(2), horzLine(3), horzLine(4), width);     % Horizontal line
    
    % The slider
    Screen('DrawLine', window, sliderColor, x, rect(4)*scalaPosition - lineLength, x, rect(4)*scalaPosition  + lineLength, width);
    
    % Caculates position
    if rangeType == 1
        position = round((x)-mean(scaleRange));           % Calculates the deviation from the center
        position = (position/max(scaleRangeShifted))*100; % Converts the value to percentage
        %pos = position*99/100+1 %converts from 0 to 100 to 1 to 100.
    elseif rangeType == 2
        position = round((x)-min(scaleRange));                       % Calculates the deviation from 0.
        position = (position/(max(scaleRange)-min(scaleRange)))*100; % Converts the value to percentage
    end
    
    
    % Display position
    if displayPos
        DrawFormattedText(window, num2str(round(position)), 'center', rect(4)*(scalaPosition + 0.05));
    end
    
    
    %Drawing the message as text
    %text size should still be instructsize, initialized at start of loop.
    WriteLine(window, message, wordcolor, 100, 100, rect(4)*(scalaPosition - 0.125), 2);
    
    
    %Drawing the word pair.
    Screen('TextSize', window, textSize);
    WriteCentered(window, wordpair{1}, xPos-xbuffer, yPos-yadjust-ybuffer, wordcolor);
    WriteCentered(window, ndash, xPos, yPos-yadjust-ybuffer, wordcolor);
    WriteCentered(window, wordpair{2}, xPos+xbuffer, yPos-yadjust-ybuffer, wordcolor);
    

%     DrawFormattedText(window, message, 'center', rect(4)*(scalaPosition - 0.1));
    
    % Flip screen
    onsetStimulus = Screen('Flip', window);
    
    % Check if answer has been given
    if strcmp(device, 'mouse')
        secs = GetSecs;
        if buttons(responseKey) == 1
            answer = 1;
        end
    elseif strcmp(device, 'keyboard')
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyCode(responseKey) == 1
            answer = 1;
        end
    else
        error('Unknown device');
    end
    
    % Abort if answer takes too long
    if secs - t0 > aborttime
        break
    end
end
%% Wating that all keys are released and delete texture
KbReleaseWait; %Keyboard
KbReleaseWait(1); %Mouse
if drawImage == 1
    Screen('Close', stimuli);
end
%% Calculating the rection time and the position
RT                = (secs - t0); %*1000;   % converting RT to millisecond
end