clear all
load ~/task_mod_1.mat
load ../66_Hagmann_Cabral.mat
!rm test.avi
a = xths{1};

numberofsecs = 280;
framerate=25;
samplespersec = length(a)./numberofsecs;
samplingrate = samplespersec./framerate;
ars = a(1:samplingrate:end,:);

azs = -214:(diff([-214 100])/length(ars)):100;
els = 34:-(diff([7 34])/length(ars)):7;

%azs = zeros(1,length(ars));
%els = ones(1,length(ars))*90;

writerObj = VideoWriter('test.avi');
writerObj.FrameRate=framerate;
open(writerObj);

[handle, nodehandles]= ball_and_stick(C(Order,Order),L(Order,Order),talairach_66(Order,:),100);
set(handle, 'Position', [1 1 800 600])
%Set the camera to manual, so that any change to azs and els makes all
%the difference without some weird zoomatron.[
%camtarget('manual')
camproj('perspective')

ballcmap = jet(1000);
for i = 1:length(ars)
    for j = 1:numel(nodehandles)
        set(nodehandles(j),'FaceColor',ballcmap(ceil(((a(i,j)+pi)/(2*pi))*1000),:))
    end
    %set the view
    view(azs(i),els(i));
    %For some reason it doesnt work, and in any case, would dramatically
    %reduce runtime, but here is where antialisaing would happen (commented
    %out)
    %aaf = myaa;
    frame = getframe(handle);
    writeVideo(writerObj,frame);
    disp(num2str(i));
    %close(handle);
    %close(aaf);
    %pause(0.1);
end

close(writerObj);