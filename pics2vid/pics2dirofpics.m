%% pics2dirofpics.m, v.1.2, 29-sep-2014
%                    v.1.1, 24-sep-2014
%                    v.0.x, 30-aug-2014
%  Produces a list of JPG frames from a set of dated pics, before using
%  MEncoder to produce the final video.
%
%  - the actual period AP is accelerated to fit into ML seconds of movie
%  - the pics are chained in a smart interpolation [fondu-enchainé]
%  => http://octave.sourceforge.net/video/ (attempt to replace MATLAB)
%  => http://octave.sourceforge.net/video/overview.html
%  => (install) http://octave.sourceforge.net/index.html => To install a package,
%     use the pkg command from the Octave prompt by typing:
%     pkg install -forge package_name 
%% I/O
%  I/ dataList (file): list of pics names, with datum (seconds) in 1st column
%     ML (integer): Movie Length in seconds (AP is not to be given)
%  O/ movie (AVI file): non-compressed AVI file, with <fps> frame per seconds
%% (c) Boris Segret, 07/2014
%
%  recadrages:
%  - MTSAT2, bandeau = Ligne 14+27, Col.16+400
%  - MTSAT2, centre  = Ligne 220+400, Col 220+400
%    picNN(1:400,1:400,1:3)=picN0(250:649,220:619,1:3);
%    picNN(371:400,1:400,1:3)=picN0(14:(14+29),16:(16+399),1:3);
%    figure(1);imagesc(picNN);


clear;
inputNames=caseread('inOctave');

listofpics=strtok(inputNames(1,:));
srcofpics=strtok(inputNames(2,:));
moviename=strtok(inputNames(3,:));
namePic=[srcofpics '/temp/' moviename '_'];
ML=20;
fps=25; % Frame per second in the output movie
NR=400; % Nb.of rows in the final pic
NC=400; % Nb.of columns in the final pic
%cfr=2.54; % Conversion in the number of frames (!!)
smoothiness=1.; % From continuous (1.) to no (0.) interpolation between pics

%- Input: list of pics filenames, sorting, timesteps identification
fl=fopen(listofpics,'r');
[pnumb, neof]=fscanf(fl, '%i %i %*s\n', [2 inf]);
fclose(fl);
nbpics=size(pnumb,2);
pname=repmat(char(0),[nbpics max(pnumb(2,:))]);
fl=fopen(listofpics,'r');
for i=1:nbpics
    [pname(i,1:pnumb(2,i)), neof]=fscanf(fl, '%*s %*s %s\n', 1);
end
fclose(fl);

[pstp(1,:),istp]=sort(pnumb(1,:));
dstp=pstp(1,:)-circshift(pstp(1,:),[0 1]);
% pstp: sorted dates of available pics (istp: indexes of the pics)
%       pstp(1,:) : in real seconds
%       pstp(2,:) : in frame number
% dstp: real_seconds between 2 consecutive pics, dstp(1)=-(total duration)

nfr=ML*fps; % Nb of frames to be produced
acc=double(-dstp(1))/(nfr-1); % acceleration rate in real_seconds/frame
pstp(2,:)=(pstp(1,:)-pstp(1,1))/acc;
figure(3);plot(pstp(1,:), pstp(2,:)); title('Nb of frame vs. real date of pic (s)');

%- Outer loop to write the pics
ifr=floor(pstp(2,1))+1;
pic=imread([srcofpics '/' pname(istp(1),:)]);
picN0(1:NR,1:NC,1:3)=pic(250:649,220:619,1:3);
picN0((NR-29):NR,1:NC,1:3)=pic(14:(14+29),16:(16+399),1:3);
figure(1);imagesc(picN0); title(pname(istp(1),:));
iim=2;

jfr=floor(pstp(2,iim)); % needed for first iteration
%- Inner loop
while (jfr <= nfr) && (iim <= nbpics)
    jfr=floor(pstp(2,iim));
    pic=imread([srcofpics '/' pname(istp(iim),:)]);
    picN1(1:NR,1:NC,1:3)=pic(250:649,220:619,1:3);
    picN1((NR-29):NR,1:NC,1:3)=pic(14:(14+29),16:(16+399),1:3);
    figure(2);imagesc(picN1); title(pname(istp(iim),:));

    %- Interpolation from picN0 to picN1
    iifr=floor(ifr+(((1.-smoothiness)/2.)*dstp(iim)/acc));
    jjfr=floor(jfr-(((1.-smoothiness)/2.)*dstp(iim)/acc));

    for i=ifr:1:iifr
        % first part between picN0 and picN1: only picN0 is written
        indPic=sprintf('%05i', i);
        imwrite(picN0, [namePic indPic '.jpg']);
    end
    for i=iifr:1:jjfr
        % 2nd+3rd parts between picN0 and picN1: an interpolation is written
        if (iifr==jjfr)
            N0weight=1.;
        else
            N0weight=1.-(i-iifr)/(jjfr-iifr);
        end
        picNi=N0weight*picN0+(1.-N0weight)*picN1;
        indPic=sprintf('%05i', i);
        imwrite(picNi, [namePic indPic '.jpg']);
    end
    for i=jjfr:1:jfr
        % fourth part between picN0 and picN1: only picN1 is written
        indPic=sprintf('%05i', i);
        imwrite(picN1, [namePic indPic '.jpg']);
    end

    ifr=jfr;
    picN0=picN1;
    figure(1);imagesc(picN0); title(pname(istp(iim),:));
    iim=iim+1;
end

