dir = getDirectory("Choose a Directory");
list = getFileList(dir);
setBatchMode(true);

for (i=0; i<list.length;i++) {
	if (startsWith(list[i], "Count")) {
		open(dir + list[i]);
		if (roiManager("count") > 0) {
			roiManager("Deselect");
			roiManager("Delete");
		}
		
		run("Remove Overlay");
		run("Select None");
		
		name = getTitle();
		
		roiManager("Open", dir + "ROI_" + substring(name,6,lengthOf(name)-4) + ".zip");
		
		// Modifications to fit U-Net
		roiManager("Select", 0);
		run("Make Inverse");
		roiManager("Add");
		roiManager("Delete");
		
		roiManager("Select", roiManager("count")-1);
		roiManager("Remove Channel Info");
		roiManager("Remove Slice Info");
		roiManager("Remove Frame Info");
		roiManager("Rename", "ignore");

		counts = roiManager("count");
		
		x = newArray(0);
		y = newArray(0);
		
		for (j=0;j<counts-1;j++){ 
		    roiManager("Select", j);
		    roiManager("Rename", "cell");
		    roiManager("Remove Channel Info");
			roiManager("Remove Slice Info");
			roiManager("Remove Frame Info");
		}
		
		rename("temp");
		run("Split Channels");
		run("Merge Channels...", "c1=C1-temp c2=C2-temp c3=C3-temp c4=C4-temp create");
		run("From ROI Manager");
		
		saveAs("tiff", dir + "UNet_" + name);
		run("Close All");
	}
}