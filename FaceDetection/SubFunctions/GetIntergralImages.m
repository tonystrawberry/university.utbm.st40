function IntegralImages = GetIntergralImages(Picture,Options)
    % Make integral image from a Picture
    %
    %
    % Function is written by D.Kroon University of Twente (November 2010)

    [Picture, Ratio] = getPreProcessingImage(Picture, Options);

    % Make the integral image for fast region sum look up
    IntegralImages.ii=cumsum(cumsum(Picture,1),2);
    IntegralImages.ii=padarray(IntegralImages.ii,[1 1], 0, 'pre');

    % Make integral image to calculate fast a local standard deviation of the
    % pixel data
    IntegralImages.ii2=cumsum(cumsum(Picture.^2,1),2);
    IntegralImages.ii2=padarray(IntegralImages.ii2,[1 1], 0, 'pre');

    % Store other data
    IntegralImages.width = size(Picture,2);
    IntegralImages.height = size(Picture,1);
    IntegralImages.Ratio=Ratio;
