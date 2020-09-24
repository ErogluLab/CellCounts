' Run U-Net and place mask in the last channel
' Must run the GUI with the exact same configuration at least once before running this script.

waitForUser("Make sure that you have run the U-Net with the same settings at least once before running this script.");
dir = getDirectory("[Choose Source Directory]");
list  = getFileList(dir);
path = File.openDialog("Choose a UNet caffemodel File");
modeldef = File.directory + substring(File.getName(path),0,lengthOf(File.getName(path))-14) + ".modeldef.h5";

for (i=0; i<list.length; i++) {
	if (endsWith(list[i], ".tif") && !startsWith(list[i], "Seg")) {
		setBatchMode(false);
		open(dir + list[i]);
		getDimensions(width, height, channels, slices, frames);
		name = getTitle();
		run("Remove Overlay");
		run("16-bit");
		call('de.unifreiburg.unet.SegmentationJob.processHyperStack', 'modelFilename=' + modeldef + ',weightsFilename=' + path + ',Tile shape (px):=404x404,gpuId=GPU 0,useRemoteHost=true,hostname=localhost,port=22,username=eroglulab,RSAKeyfile=/home/eroglulab/.ssh/id_rsa,processFolder=/home/eroglulab/Desktop/cellnet/,average=none,keepOriginal=true,outputScores=false,outputSoftmaxScores=true');
		close();
		setBatchMode(true);
		run("Split Channels");
		rename("mask"); // channel 2
		run("16-bit");
		selectImage(name);
		if (channels > 1) {
			rename("temp");
			run("Split Channels");
		} else {
			rename("C1-temp");
		}
		arg = "";
		for (j=1; j<=channels; j++) {
			arg = arg + " c" + j + "=" + "C" + j + "-temp";
		}
		arg = arg + " c" + j + "=mask create";
		run("Merge Channels...", arg);
		set_mask(channels+1);
		saveAs("tiff", dir + "Seg_" + list[i]);
		run("Close All");
	}
}

function set_mask(chan) { // Mark that channel is a mask.
	Stack.setChannel(chan);
	setPixel(0,0,251);
	setPixel(1,0,148);
	setPixel(0,1,249);
}