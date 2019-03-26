tic; % Start timer.
clc; % Clear command window.
clearvars; % Get rid of variables from prior run of this m-file.
fprintf('Running Cell Counting.m...\n'); % Message sent to command window.
workspace; % Make sure the workspace panel with all the variables is showing.
imtool close all;  % Close all imtool figures.
format long g;
format compact;
captionFontSize = 14;
%plate C well 3, image 9
%plate D well 4, image 11

%==========================================================================
% Read in a data file of cell images
baseFileName = '25,000Cells/Image11.tif';    %\CellRun3\CHO cells run 3\Cell_runs\     
folder = fileparts(which(baseFileName)); % Determine where demo folder is (works with all versions).
fullFileName = fullfile(folder, baseFileName);
if ~exist(fullFileName, 'file')
	% It doesn't exist in the current folder.
	% Look on the search path.
	if ~exist(baseFileName, 'file')
		% It doesn't exist on the search path either.
		% Alert user that we can't find the image.
		warningMessage = sprintf('Error: the input image file\n%s\nwas not found.\nClick OK to exit the demo.', fullFileName);
		uiwait(warndlg(warningMessage));
		fprintf(1, 'Finished running cellsDemo.m.\n');
		return;
	end
	% Found it on the search path.  Construct the file name.
	fullFileName = baseFileName; % Note: don't prepend the folder.
end


originalImage = imread(fullFileName);
% Check to make sure that it is grayscale, just in case the user substituted their own image.
[rows, columns, numberOfColorChannels] = size(originalImage);
if numberOfColorChannels > 1
	promptMessage = sprintf('Your image file has %d color channels.\nThis program was designed for grayscale images.\nDo you want me to convert it to grayscale for you so you can continue?', numberOfColorChannels);
	button = questdlg(promptMessage, 'Continue', 'Convert and Continue', 'Cancel', 'Convert and Continue');
	if strcmp(button, 'Cancel')
		fprintf(1, 'Finished running cell counter.m.\n');
		return;
	end
	% Do the conversion using standard book formula
	originalImage = rgb2gray(originalImage);
end


%==========================================================================
% Display the grayscale image.
subplot(3, 3, 1);
imshow(originalImage);
% Maximize the figure window.
set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
% Force it to display RIGHT NOW (otherwise it might not display until it's all done, unless you've stopped at a breakpoint.)
drawnow;
caption = sprintf('Original binary image of segmented cells from CNN.');
title(caption, 'FontSize', captionFontSize);
axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.


%==========================================================================
% Obtain histogram and display it.
[pixelCount, grayLevels] = imhist(originalImage);
subplot(3, 3, 2);
bar(pixelCount);
title('Histogram of original image', 'FontSize', captionFontSize);
xlim([0 grayLevels(end)]); % Scale x axis manually.
grid on;
%==========================================================================


% Threshold the image to get a binary image (only 0's and 1's) of class "logical."
% Method #1: using im2bw()
%   normalizedThresholdValue = 0.4; % In range 0 to 1.
%   thresholdValue = normalizedThresholdValue * max(max(originalImage)); % Gray Levels.
%   binaryImage = im2bw(originalImage, normalizedThresholdValue);       % One way to threshold to binary
% Method #2: using a logical operation.
thresholdValue = 1;   %default is set at 100 for this run
binaryImage = originalImage < thresholdValue; % Bright objects will be chosen if you use >.
% ========== IMPORTANT OPTION ============================================================
% Use < if you want to find dark objects instead of bright objects.
%   binaryImage = originalImage < thresholdValue; % Dark objects will be chosen if you use <.

% Do a "hole fill" to get rid of any background pixels or "holes" inside
% the cells. Useful if cells are being captured whilst in the midst of
% mitosis
binaryImage = imfill(binaryImage, 'holes');


%==========================================================================
% Show the threshold as a vertical red bar on the histogram.
hold on;
maxYValue = ylim;
line([thresholdValue, thresholdValue], maxYValue, 'Color', 'r');
% Place a text label on the bar chart showing the threshold.
annotationText = sprintf('Thresholded at %d grey levels', thresholdValue);
% For text(), the x and y need to be of the data class "double" so let's cast both to double.
text(double(thresholdValue + 5), double(0.5 * maxYValue(2)), annotationText, 'FontSize', 10, 'Color', [0 .5 0]);
text(double(thresholdValue - 70), double(0.94 * maxYValue(2)), 'Background', 'FontSize', 10, 'Color', [0 0 .5]);
text(double(thresholdValue + 50), double(0.94 * maxYValue(2)), 'Foreground', 'FontSize', 10, 'Color', [0 0 .5]);

% Display the binary image.
subplot(3, 3, 3);
imshow(binaryImage); 
title('Binary Image, obtained by thresholding', 'FontSize', captionFontSize); 

% Identify individual cells by seeing which pixels are connected to each other.
% Each group of connected pixels will be given a label, a number, to identify it and distinguish it from the other cells.
% Do connected components labeling with either bwlabel() or bwconncomp().
labeledImage = bwlabel(binaryImage, 8);     % Label each cell so measurements can be made
% labeledImage is an integer-valued image where all pixels in the cells have values of 1, or 2, or 3, or ... etc.
subplot(3, 3, 4);
imshow(labeledImage, []);  % Show the gray scale image.
title('Labeled Image, from bwlabel()', 'FontSize', captionFontSize);


%==========================================================================
% Assign each cell a different colour so as to distinguish each from each
% other
coloredLabels = label2rgb (labeledImage, 'hsv', 'k', 'shuffle'); % pseudo random color labels
% coloredLabels is an RGB image.  We could have applied a colormap instead 
subplot(3, 3, 5);
imshow(coloredLabels);



axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.
caption = sprintf('Pseudo colored labels, from label2rgb().\ncells are numbered from top to bottom, then from left to right.');
title(caption, 'FontSize', captionFontSize);
%==========================================================================
%==========================================================================


% Get all the cell properties
cellMeasurements = regionprops(labeledImage, originalImage, 'all');
numberOfCells = size(cellMeasurements, 1);

% bwboundaries() returns a cell array, where each cell contains the row/column coordinates for an object in the image.
% Plot the borders of all the cells on the original grayscale image using the coordinates returned by bwboundaries.
subplot(3, 3, 6);
imshow(originalImage);
title('Outlines, from bwboundaries()', 'FontSize', captionFontSize); 
axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.
hold on;
boundaries = bwboundaries(binaryImage);
numberOfBoundaries = size(boundaries, 1);
for k = 1 : numberOfBoundaries
	thisBoundary = boundaries{k};
	plot(thisBoundary(:,2), thisBoundary(:,1), 'g', 'LineWidth', 2);
end
hold off;

textFontSize = 14;	% Used to control size of "cell number" labels put atop the image.
labelShiftX = -7;	% Used to align the labels in the centers of the cells.
cellECD = zeros(1, numberOfCells);
% Print header line in the command window.
fprintf(1,'cell #      Mean Intensity  Area   Perimeter    Centroid       Diameter\n');
% Loop over all cells printing their measurements to the command window.
for k = 1 : numberOfCells           % Loop through all s.
	% Find the mean of each cell.  (R2008a has a better way where you can pass the original image
	% directly into regionprops.  The way below works for all versions including earlier versions.)
	thiscellsPixels = cellMeasurements(k).PixelIdxList;  % Get list of pixels in current cell.
	meanGL = mean(originalImage(thiscellsPixels)); % Find mean intensity (in original image!)
	meanGL2008a = cellMeasurements(k).MeanIntensity; % Mean again, but only for version >= R2008a
	
	cellArea = cellMeasurements(k).Area;		% Get area.
	cellPerimeter = cellMeasurements(k).Perimeter;		% Get perimeter.
	cellCentroid = cellMeasurements(k).Centroid;		% Get centroid one at a time
	cellECD(k) = sqrt(4 * cellArea / pi);					% Compute ECD - Equivalent Circular Diameter.
	fprintf(1,'#%2d %17.1f %11.1f %8.1f %8.1f %8.1f % 8.1f\n', k, meanGL, cellArea, cellPerimeter, cellCentroid, cellECD(k));
	% Put the "cell number" labels on the "boundaries" grayscale image.
	text(cellCentroid(1) + labelShiftX, cellCentroid(2), num2str(k), 'FontSize', textFontSize, 'FontWeight', 'Bold');
end
%==========================================================================


%Alternative Centroid Method
allcellCentroids = [cellMeasurements.Centroid];
centroidsX = allcellCentroids(1:2:end-1);
centroidsY = allcellCentroids(2:2:end);
% Put the labels on the rgb labeled image also.
subplot(3, 3, 5);
for k = 1 : numberOfCells           % Loop through all cells.
	text(centroidsX(k) + labelShiftX, centroidsY(k), num2str(k), 'FontSize', textFontSize, 'FontWeight', 'Bold');
end
%==========================================================================



% Demonstrate how to select certain cells based using the ismember() function.
allcellIntensities = [cellMeasurements.MeanIntensity];
allcellAreas = [cellMeasurements.Area];
% Get a list of the cells that meet our criteria and we need to keep.
% These will be logical indices - lists of true or false depending on whether the feature meets the criteria or not.
% for example [1, 0, 0, 1, 1, 0, 1, .....].  Elements 1, 4, 5, 7, ... are true, others are false.
allowableIntensityIndexes = (allcellIntensities > 1) & (allcellIntensities < 350);
allowableAreaIndexes = allcellAreas < 4000; % Take the small objects.
% Now let's get actual indexes, rather than logical indexes, of the  features that meet the criteria.
% for example [1, 4, 5, 7, .....] to continue using the example from above.
keeperIndexes = find(allowableIntensityIndexes & allowableAreaIndexes);
% Extract only those cells that meet our criteria, and
% eliminate those cells that don't meet our criteria.
% Note how we use ismember() to do this.  Result will be an image - the same as labeledImage but with only the cells listed in keeperIndexes in it.
keepercellsImage = ismember(labeledImage, keeperIndexes);
% Re-label with only the keeper cells kept.
labeledDimeImage = bwlabel(keepercellsImage, 8);     % Label each cell so we can make measurements of it
% Now we're done.  We have a labeled image of cells that meet our specified criteria.
subplot(3, 3, 7);
imshow(labeledDimeImage, []);
axis image;
title('"Keeper" cells (3 brightest cells in a re-labeled image)', 'FontSize', captionFontSize);

% Plot the centroids in the original image in the upper left.
% Dimes will have a red cross, nickels will have a blue X.
message = sprintf('Now I will plot the centroids over the original image in the upper left.\nPlease look at the upper left image.');
reply = questdlg(message, 'Plot Centroids?', 'OK', 'Cancel', 'Cancel');
% Note: reply will = '' for Upper right X, 'OK' for OK, and 'Cancel' for Cancel.
if strcmpi(reply, 'Cancel')
	return;
end
subplot(3, 3, 1);
hold on; % Don't blow away image.
for k = 1 : numberOfCells           % Loop through all keeper cells.
	
	itsADime = allcellAreas(k) < 2200; % Dimes are small.
	if itsADime
		
		plot(centroidsX(k), centroidsY(k), 'r+', 'MarkerSize', 10, 'LineWidth', 2);
	else
		
		plot(centroidsX(k), centroidsY(k), 'bx', 'MarkerSize', 10, 'LineWidth', 2);
	end
end

%==========================================================================


elapsedTime = toc;
% Alert user that the demo is done and give them the option to save an image.
message = sprintf('Done making measurements of the features.\n\nElapsed time = %.2f seconds.', elapsedTime);
message = sprintf('%s\n\nCheck out the figure window for the images.\nCheck out the command window for the numerical results.', message);
message = sprintf('%s\n\nDo you want to save the pseudo-colored image?', message);
reply = questdlg(message, 'Save image?', 'Yes', 'No', 'No');
% Note: reply will = '' for Upper right X, 'Yes' for Yes, and 'No' for No.
if strcmpi(reply, 'Yes')
	% Ask user for a filename.
	FilterSpec = {'*.PNG', 'PNG Images (*.png)'; '*.tif', 'TIFF images (*.tif)'; '*.*', 'All Files (*.*)'};
	DialogTitle = 'Save image file name';
	% Get the default filename.  Make sure it's in the folder where this m-file lives.
	% (If they run this file but the cd is another folder then pwd will show that folder, not this one.
	thisFile = mfilename('fullpath');
	[thisFolder, baseFileName, ext] = fileparts(thisFile);
	DefaultName = sprintf('%s/%s.tif', thisFolder, baseFileName);
	[fileName, specifiedFolder] = uiputfile(FilterSpec, DialogTitle, DefaultName);
	if fileName ~= 0
		% Parse what they actually specified.
		[folder, baseFileName, ext] = fileparts(fileName);
		% Create the full filename, making sure it has a tif filename.
		fullImageFileName = fullfile(specifiedFolder, [baseFileName '.tif']);
		% Save the labeled image as a tif image.
		imwrite(uint8(coloredLabels), fullImageFileName);
		% Just for fun, read image back into the imtool utility to demonstrate that tool.
		tifimage = imread(fullImageFileName);
		imtool(tifimage, []);
	end
end
