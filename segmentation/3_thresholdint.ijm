' Create mask based on intensity
run("Set Measurements...", "area mean centroid redirect=None decimal=3");
dir = getDirectory("Choose a Directory");
list = getFileList(dir);
setBatchMode(true);
minsize = getNumber("Minimum cell area? ", 50);
starts = getString("Name starts with?", "Seg");
thr = getNumber("Threshold? ", 30000);
remove = getBoolean("Remove mask?");

for (i=0; i< list.length;i++) {
	if (startsWith(list[i], starts) && endsWith(list[i], ".tif")) {
		open(dir + list[i]);
		getDimensions(width, height, channels, slices, frames);
		
		if (!is_mask(channels)) exit("Last channel from file " + list[i] + " is not mask.");
		
		Stack.setDisplayMode("color");
		Stack.setChannel(channels);
		run("Duplicate...", " ");
		
		setThreshold(thr, 65535);
		run("Convert to Mask");
		run("Watershed");
		run("Analyze Particles...", "size=" + minsize + "-Infinity display add clear");
		saveAs("Results", dir + list[i] + ".csv");
		close("Results");

		// ROI processing just in case
		counts = roiManager("count");
		for (j = 0; j < counts; j++){ 
		    roiManager("Select", j);
		    roiManager("Rename", "cell");
		    roiManager("Remove Channel Info");
			roiManager("Remove Slice Info");
			roiManager("Remove Frame Info");
		}
		
		close();

		if (remove) {
			name = getTitle();
			rename("temp");
			run("Split Channels");
			close();
			if (channels > 2) {
				arg = "";
				for (j=1; j<channels; j++) {
					arg = arg + " c" + j + "=" + "C" + j + "-temp";
				}
				arg = arg + " create";
				run("Merge Channels...", arg);
			}
			rename(name);
		}

		run("Remove Overlay");
		run("From ROI Manager");
		saveAs("tiff", dir + "ROI" + substring(list[i],3, lengthOf(list[i])));
		close();
	}
}

function is_mask(chan) {
	Stack.setChannel(chan);
	if (getPixel(0,0) == 251 && getPixel(1,0) == 148 && getPixel(0,1) == 249) {
		return true;
	} else {
		return false;
	}
}