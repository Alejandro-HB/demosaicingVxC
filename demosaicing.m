%Alejandro Hernandez Baca
%Demosaicing techniques


%============RUN THIS SECTION FIRST, THEN, THE RESPECTIVE TECHNIQUE SECTION======
clc;
clear all;
close all;

im = imread('./imagesDemosaicing/Frutas_rggb.jpg');
realImage = imread('./imagesDemosaicing/Frutas_rggb_color.jpg');

%im = imread('./imagesDemosaicing/Frutas10r_rggb.jpg');
%realImage = imread('./imagesDemosaicing/Frutas_grbg_color.jpg');

%imshow(im);
[imageHeight, imageWidth] = size(im);

%Creating masks for the Bayer pattern RGGB
bayer_red = repmat([1 0; 0 0], ceil(imageHeight/2), ceil(imageWidth/2));
bayer_red = uint8(bayer_red);
bayer_blue = repmat([0 0; 0 1], ceil(imageHeight/2), ceil(imageWidth/2));
bayer_blue = uint8(bayer_blue);
bayer_green = repmat([0 1; 1 0], ceil(imageHeight/2), ceil(imageWidth/2));
bayer_green = uint8(bayer_green);

%Applying the masks to the image
imR = double(im) .* double(bayer_red);
imG = double(im) .* double(bayer_green);
imB = double(im) .* double(bayer_blue);

%%
%Nearest Neighbors

%Blue channel
%rows
%Red channel
for i=1:imageHeight
    for j=1:imageWidth
        if(mod(i,2)==0)
            imR(i,j)=imR(i-1,j);
        end
        if(imR(i,j)==0)
            imR(i,j)=imR(i,j-1);
        end
    end
end


%Green channel
for i=1:imageHeight
    for j=1:imageWidth
        if(imG(i,j)==0)
            if(i<imageHeight)
                imG(i,j)=imG(i+1,j);
            %For the las row, when we can not
            %get a value from the next row (doesnt exist)
            %we got it from the previous one
            else
                imG(i,j)=imG(i-1,j);
            end
            
        end
    end
end

%Blue channel
for i=1:2:imageHeight
    for j=1:2:imageWidth
        if(imB(i,j)==0)
            imB(i,j)=imB(i+1,j+1);
            imB(i+1,j)=imB(i+1,j+1);
            imB(i,j+1)=imB(i+1,j+1);
        end
    end
end

%Merge channels
figure(1);
finalIm = cat(3, imR, imG, imB);
finalIm = uint8(finalIm);
imshow(finalIm);

figure(2);
imshow(realImage);

mse=immse(finalIm(2:imageHeight,2:imageWidth,:), realImage(2:imageHeight,2:imageWidth,:));
fprintf('Nearest Neighbors interpolation MSE: %.2f', mse);


%%
%Bilineal interpolation


%Red channel
%rows
for i=1:2:imageHeight
    for j=1:imageWidth
        if(imR(i,j)==0)&&(j<imageWidth)
            imR(i,j)=mean([imR(i,j-1), imR(i,j+1)]);
        end
    end
end
%cols
for i=1:imageWidth
    for j=2:2:imageHeight
        if(imR(j,i)==0)&&(j<imageHeight)
            imR(j,i)=mean([imR(j-1,i), imR(j+1,i)]);
        else
            imR(j,i)=mean([imR(j-1,i), imR(j-2,i)]);
        end
    end
end

%Green channel
for i=2:imageHeight
    for j=2:imageWidth
        if(imG(i,j)==0)&&(i<imageHeight)&&(j<imageWidth)
            imG(i,j)=mean([imG(i-1,j), imG(i+1,j), imG(i,j-1), imG(i,j+1)]);
        end
    end
end

%Blue channel
%rows
for i=2:2:imageHeight
    for j=3:imageWidth
        if(imB(i,j)==0)&&(i<imageHeight)&&(j<imageWidth)
            imB(i,j)=mean([imB(i,j-1), imB(i,j+1)]);
        end
    end
end

%cols
for i=2:imageWidth
    for j=3:2:imageHeight
        if(imB(j,i)==0)&&(j<imageHeight)
            imB(j,i)=mean([imB(j-1,i), imB(j+1,i)]);
        else
            imR(j,i)=mean([imB(j-1,i), imB(j-2,i)]);
        end
    end
end

%Merge channels
figure(1);
finalIm = cat(3, imR, imG, imB);
finalIm = uint8(finalIm);
imshow(finalIm);

figure(2);
imshow(realImage);

mse=immse(finalIm(2:imageHeight-1,2:imageWidth-1, :), realImage(2:imageHeight-1,2:imageWidth-1, :));
fprintf('Bilineal interpolation MSE: %.2f', mse);

%%
%%Cubic interpolation
x1=1;
x2=3;
x3=5;
x4=7;
xeval=2;

M=[ 1, x1, x1.^2, x1.^3;
    1, x2, x2.^2, x2.^3;
    1, x3, x3.^2, x3.^3;
    1, x4, x4.^2, x4.^3; ];
M_inv=inv(M);

%Red channel
%rows
for i =1:2:imageHeight-1
    for j=1:2:imageWidth-6
        F=[imR(i,j), imR(i,j+2), imR(i,j+4), imR(i,j+6),];
        A=M_inv*transpose(F);
        f_x=dot([1, xeval, xeval.^2, xeval.^3], A);
        imR(i, j+1)=f_x;
    end
end
%cols
for i=1:imageWidth-1
    for j=1:2:imageHeight-6
        F=[imR(j,i), imR(j+2,i), imR(j+4,i), imR(j+6,i),];
        A=M_inv*transpose(F);
        f_x=dot([1, xeval, xeval.^2, xeval.^3], A);
        imR(j+1, i)=f_x;
    end
end

%Blue channel
%rows
for i =2:2:imageHeight
    for j=2:2:imageWidth-6
        F=[imB(i,j), imB(i,j+2), imB(i,j+4), imB(i,j+6),];
        A=M_inv*transpose(F);
        f_x=dot([1, xeval, xeval.^2, xeval.^3], A);
        imB(i, j+1)=f_x;
    end
end

%cols
for i=2:imageWidth
    for j=2:2:imageHeight-6
        F=[imB(j,i), imB(j+2,i), imB(j+4,i), imB(j+6,i),];
        A=M_inv*transpose(F);
        f_x=dot([1, xeval, xeval.^2, xeval.^3], A);
        imB(j+1, i)=f_x;
    end
end

%Green channel
%rows
for i =1:2:imageHeight
    for j=2:2:imageWidth-6
        F=[imG(i,j), imG(i,j+2), imG(i,j+4), imG(i,j+6),];
        A=M_inv*transpose(F);
        f_x=dot([1, xeval, xeval.^2, xeval.^3], A);
        imG(i, j+1)=f_x;
    end
end

%cols
for i=2:imageWidth
    for j=1:2:imageHeight-6
        F=[imG(j,i), imG(j+2,i), imG(j+4,i), imG(j+6,i),];
        A=M_inv*transpose(F);
        f_x=dot([1, xeval, xeval.^2, xeval.^3], A);
        imG(j+1, i)=f_x;
    end
end

%Merge channels
figure(1);
finalIm = cat(3, imR, imG, imB);
finalIm = uint8(finalIm);
imshow(finalIm);

figure(2);
imshow(realImage);

mse=immse(finalIm(2:imageHeight-5,2:imageWidth-5, :), realImage(2:imageHeight-5,2:imageWidth-5, :));
fprintf('Cubic interpolation MSE: %.2f', mse);


%%
%Merge channels
finalIm = cat(3, imR, imG, imB);
finalIm = uint8(finalIm);
imshow(finalIm);

figure();
demosaiced_matlab=demosaic(im, 'rggb');
imshow(demosaiced_matlab);

mse=immse(finalIm(2:imageHeight-1,2:imageWidth-1), realImage(2:imageHeight-1,2:imageWidth-1));
fprintf('MSE: %.2f', mse);

