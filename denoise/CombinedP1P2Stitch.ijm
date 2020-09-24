' Iterate through each subfolder, max project and save into corresponding "stitch" folder

var dir1;
var list1;
var dir2;
var list2;
var dirbig;
var listbig;
var dirflat;
var dirtiff;
var listp1;
var listp2;
var numchan;
var batch;
var correction;
var train;
var foldername;
var process;

var stitch;
var dir;
var dirmax;
var list;
var lastfile;
var maxproj;
var zslices;
var currentstitch = 0; // Number of groups - 1
setBatchMode(true);

// To stitch in 3D, remove the line below.
eval("bsh", "mpicbg.stitching.GlobalOptimization.ignoreZ = true");

dialoggen();

// Phase 1
if (!batch || train) { // Individual
	dir1 = getDirectory("Choose P1");
	list1 = getFileList(dir1);

	if (numchan > 2) {
		dir2 = getDirectory("Choose P2");
		list2 = getFileList(dir2);
	}
	if (!train) {
		checkTileConfig(dir1, true);
	}
	getdirflat();
	processfolder();
	
} else { // Batch
	dirbig = getDirectory("Choose big directory");
	listbig = getFileList(dirbig);
	getdirflat();
	if (numchan < 3) { // One phase
		for (j = 0; j < listbig.length; j++) {
			if (indexOf(listbig[j], "Cycle") != -1 && !endsWith(listbig[j], "_tiff/") && endsWith(listbig[j], "/")) { // Check TileConfig
				checkTileConfig(dirbig + listbig[j], true);
			}
		}
		for (j = 0; j < listbig.length; j++) {
			if (indexOf(listbig[j], "Cycle") != -1 && !endsWith(listbig[j], "_tiff/") && endsWith(listbig[j], "/")) { 
				dir1 = dirbig + listbig[j];
				list1 = getFileList(dir1);
				processfolder();
			}
		}
	} else { // Batch two phases
		listp1 = newArray();
		listp2 = newArray();
		for (j = 0; j < listbig.length; j++) {
			new = listbig[j];
			cycloc = indexOf(new, "P1_Cycle");
			if (((endsWith(new, "/") || endsWith(new, "\\")) && cycloc != -1) && !endsWith(new, "tiff/") && endsWith(listbig[j], "/")) {
				checkTileConfig(dirbig + new, true);
			}
		}
		
		for (j = 0; j < listbig.length; j++) {
			new = listbig[j];
			cycloc = indexOf(new, "P1_Cycle");
			if (((endsWith(new, "/") || endsWith(new, "\\")) && cycloc != -1) && !endsWith(new, "tiff/")) { // Check if directory and from Olympus
				p2index = -1;
				newp2 = substring(new,0,cycloc) + "P2_Cycle";
				idx = -1;
				while (p2index == -1) {
					idx++;
					p2index = indexOf(listbig[idx], newp2);
				}

				if (p2index != -1) {
					listp1 = Array.concat(listp1, new);
					listp2 = Array.concat(listp2, listbig[idx]);
				} else {
					exit("Unequal P1 and P2 folder. Please recheck naming of " + new + ".");
				}
			}
		}
	
		for (j = 0; j < listp1.length; j++) {
			dir1 = dirbig + listp1[j];
			dir2 = dirbig + listp2[j];
			list1 = getFileList(dir1);
			list2 = getFileList(dir2);
			processfolder();
		}
	}
}

// Phase 2
if (!train || stitch) {
	if (!batch) {
		dirbig = dir1 + "../";
		listbig = newArray(1);
		listbig[0] = foldername + "_tiff/";
	} else {
		listbig = getFileList(dirbig);
	}
	
	for (j = 0; j < listbig.length; j++) { // Iterate through each subfolder
		if (endsWith(listbig[j], "_tiff/")) {
			dir = dirbig + listbig[j];
			print(dir);
			list = getFileList(dir);
			lastfile = getLastFile();
			numstitch = parseInt(substring(list[lastfile], lengthOf(list[lastfile])-12,lengthOf(list[lastfile])-9)); // Number of stitches to make
			dirmax = newArray(numstitch);
			
			for (i = 0; i < numstitch; i++) { // Temp folder for images
				dirmax[i] = dir + "Max" + i+1 + "/";
				File.makeDirectory(dirmax[i]);
			}
			
			currentstitch = 0;

			for (i = 0; i < list.length; i++) { // Separate by G001..G00n
				if (endsWith(list[i], ".tif")) {
					while (indexOf(list[i], "G00" + (currentstitch+1)) == -1) { // Increase to G002 if there's no G001 in file name
						currentstitch++;
					}
					File.copy(dir + list[i], dirmax[currentstitch] + list[i]);
				}
			}
	
			containsconf = checkTileConfig(dir, false);
			
			for (i = 0; i < numstitch; i++) { // Stitch
				print("At numstitch");
				sublist = getFileList(dirmax[i]);
				
				if (sublist.length > 1) { // Protect against "skipping" G001 ... G003
					if (containsconf) {
						print("TileConfig Found");
						run("Grid/Collection stitching", "type=[Positions from file] order=[Right & Down                ] directory=[" + dirmax[i] + "] layout_file=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.1 max/avg_displacement_threshold=0.5 absolute_displacement_threshold=2 compute_overlap subpixel_accuracy computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
					} else {
						exit("No TileConfig");
					}

/*
					getDimensions(width, height, channels, slices, frames);
					if ((slices - initialslice) > 1.5*(zslices+1)) {
						noslice = true;
						setSlice(floor(slices/2));
					} else {
						noslice = false;
						if (maxproj) {
							if (zslices > slices) {
								exit("Requested Z projection impossible, not enough slices");
							}
							run("Z Project...", "start=" + floor(slices/2-zslices/2) + " stop=" + floor(slices/2+zslices/2) + " projection=[Max Intensity]");
						} else {
							setSlice(floor(slices/2));
						}
					}*/
					
					run("16-bit");
					resetMinAndMax();
					getDimensions(width, height, channels, slices, frames);
					run("Make Substack...", "channels=1-" + channels + " slices=1-" + slices-1);
					saveAs("tiff", dirbig + "Stitched_" + substring(list[lastfile],0,lengthOf(list[lastfile])-10) + i+1);
					close();
					close();
					deletedir(dirmax[i]);
				}
			}
		}
	}
}

function dialoggen() {
	// Begin first screen
	Dialog.create("Denoising pre-process");
	Dialog.addMessage("DISCLAIMER: Always check the images for z-drift and exposure before processing.\nComputational methods are not a substitute for good data acquisition technique.");
	Dialog.addRadioButtonGroup("Operation", newArray("Train", "Run"), 1, 2, "Run");
	Dialog.addNumber("Total number of channels:", 2);
	Dialog.addRadioButtonGroup("Flatfield Correction", newArray("Yes", "No"), 1, 2, "No");
	Dialog.addRadioButtonGroup("Convert files (Select Yes unless you have previously run this script.", newArray("Yes", "No"), 1, 2, "Yes");
	Dialog.show();

	if (Dialog.getRadioButton() == "Train") {
		train = true;
	} else {
		train = false;
	}
	numchan  = Dialog.getNumber();

	if (Dialog.getRadioButton() == "Yes") {
		correction = true;
	} else {
		correction = false;
	}

	if (Dialog.getRadioButton() == "Yes") {
		process = true;
	} else {
		process = false;
	}

	if (!train) runscreen();
	summary();
	// End first screen	

	Dialog.addMessage("For individual, choose P1 then P2 folder.");
	Dialog.addMessage("For batch, choose a big folder containing folders of each MATL folder.\n\t\t\t\t\t\tIf two phases, each MATL folder must end with \"P1\" or \"P2\"");
}
	
	
function runscreen() {
	Dialog.create("Options");
	Dialog.addRadioButtonGroup("Stitch", newArray("Yes", "No"), 1, 2, "Yes")
	Dialog.addRadioButtonGroup("Directory Options", newArray("Individual", "Batch"), 1, 2, "Batch")
	Dialog.show();
	
	if (Dialog.getRadioButton() == "Yes") {
		stitch = true;
	} else {
		stitch = false;
	}
	
	if (Dialog.getRadioButton() == "Individual") {
		batch = false;
	} else {
		batch = true;
	}
}

function summary() {
	Dialog.create("Summary");
	Dialog.addMessage("Here is your order, please re-check carefully.\n");

	if (train) {
		if (correction) {
			c = " with flatfield correction ";
		} else {
			c = "";
		}
		Dialog.addMessage("You want to generate a training dataset" + c + ".");
		Dialog.addMessage("Here is the input I want, in order, after you click OK:\n");
		if (numchan > 2) {
			Dialog.addMessage("\t\t- The MATL folder that contains your Phase 1 OIR files.");
			Dialog.addMessage("\t\t- The MATL folder that contains your Phase 2 OIR files.");
		} else {
			Dialog.addMessage("\t\t- The MATL folder that contains your OIR files.");
		}
		if (correction) {
			Dialog.addMessage("\t\t- The folder that contains the flatfield images.");
		}
		Dialog.addMessage("\nHere is what I'm going to give you.");
		Dialog.addMessage("\t\t- A folder that contains high and low resolution TIFF images with " + numchan + " channels.\n");
		Dialog.addMessage("\nThis folder can be fed into train.ipynb for training.");
	} else {
		if (batch) {
			word = "multiple folders";
		} else {
			word = "one folder";
		}
		Dialog.addMessage("You want to pre-process " + word + " for denoising.");
		if (correction) {
			Dialog.addMessage("You also want flatfield correction.");
		}
		Dialog.addMessage("Here is the input I want in order after you click OK:");
		if (batch) {
			Dialog.addMessage("\t\t- The big folder that contains all your MATL folders.\n");
			if (numchan > 2) {
				Dialog.addMessage("\t\t Btw, since there are " + numchan + " channels, make sure that the P1 and P2 folders are named correctly.\n");
			}
		} else {
			if (numchan > 2) {
				Dialog.addMessage("\t\t- The MATL folder that contains your Phase 1 OIR files.");
				Dialog.addMessage("\t\t- The MATL folder that contains your Phase 2 OIR files.");
			} else {
				Dialog.addMessage("\t\t- The MATL folder that contains your OIR files.");
			}
		}
		if (correction) {
			Dialog.addMessage("\t\t- The folder that contains the flatfield images.");
		}
		Dialog.addMessage("\nHere is what I'm going to give you.\n");
		Dialog.addMessage("\t\t- A folder that contains TIFF images with " + numchan + " channels.\n");
		
		if (stitch) {
			Dialog.addMessage("\t\t- Stitched TIFF images that can be denoised.");
		}
	}
	Dialog.addMessage("If you want to proceed, click OK.");
	Dialog.show();
}


function processfolder() {
	foldername = File.getName(dir1);
	if (process) {
		foldername = File.getName(dir1);
		print("Processing " + foldername);
		if (train) {
			dirtiff = dir1 + "../" + "ForTraining_" + foldername;
			File.makeDirectory(dirtiff);
			dirtiff = dirtiff + "/HighRes/";
			File.makeDirectory(dirtiff);
			
			dirlowres = newArray(3);
			for (i=0; i<3; i++) {
				dirlowres[i] = dirtiff + "../LowRes" + i+1 + "/";
				File.makeDirectory(dirlowres[i]);
			}
	
		} else {
			dirtiff = dir1 + "../" + foldername +"_tiff/";
			File.makeDirectory(dirtiff);
		}
		
		if (correction) {
			for (j = 1; j <= numchan; j++) {
				open(dirflat + "Flat_C" + j + ".tif");
			}
		}
	
		for (i=0; i<list1.length; i++) {
			if (endsWith(list1[i], ".oir") || endsWith(list1[i], ".tif") ) {
				run("Bio-Formats Importer", "open=[" + dir1 + list1[i] + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
				
				name = substring(list1[i], 0, lengthOf(list1[i])-4);
				rename("temp");
				
				if (numchan > 1) {
					run("Split Channels");
					selectWindow("C1-temp");
					rename("C1");
					selectWindow("C2-temp");
					rename("C2");
				} else {
					rename("C1");
				}
				
				if (numchan > 2) {
					/*nameloc = indexOf(list1[i], "_A01_"); // Transform P1 to P2
					p2name = substring(list1[i],0,nameloc-1) + "2" + substring(list1[i],nameloc,lengthOf(list1[i]));
					p2loc = -1;
					idx = -1;
					while (p2loc == -1) {
						idx++;
						p2loc = indexOf(list2[idx], p2name);
					}*/
					
					run("Bio-Formats Importer", "open=[" + dir2 + list2[i] + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
					rename("temp");
					if (numchan > 3) {
						run("Split Channels");
						selectWindow("C1-temp");
						rename("C3");
						selectWindow("C2-temp");
						rename("C4");
					} else {
						rename("C3");
					}
				}
	
				if (correction) {
					for (j = 1; j <= numchan; j++) {
						run("BaSiC ", "processing_stack=C" + j +" flat-field=[Flat_C" + j + ".tif] dark-field=None shading_estimation=[Skip estimation and use predefined shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Automatic temporal_drift=Ignore correction_options=[Compute shading and correct images] lambda_flat=0.50 lambda_dark=0.50");
					}
				}
	
				if (numchan > 1) {
					run("Merge Channels...", genarg(correction));
				}
	
				saveAs("tiff", dirtiff + name);
				if (train) {
					create_lowres(dirlowres, name);
				}
	
				op = getList("image.titles");
				for (img=0; img<op.length; img++) {
					if (indexOf(op[img], "Flat") == -1) {
						selectWindow(op[img]);
						close();
					}
				}
			}
		}
		run("Close All");
	}
}


function getdirflat() {
	if (correction) {
		dirflat = getDirectory("Choose Flatfield");
	}
}

function genarg(correction) {
	arg = "";
	if (correction) {
		for (i=1; i<=numchan; i++) {
			arg = arg + " c" + i + "=" + "[Corrected:C" + i + "]";
		}
	} else {
		for (i=1; i<=numchan; i++) {
			arg = arg + " c" + i + "=" + "[C" + i + "]";
		}
	}

	arg = arg + " create";
	return arg;
}


function getLastFile() {
	n = list.length - 1;
	while (!(endsWith(list[n], ".oir") || endsWith(list[n], ".tif")) || (startsWith(list[n], "Stitch"))) {
		n--;
	}
	return n;
}


function checkTileConfig(dircheck, precheck) {
	if (!precheck) {
		dircheck = substring(dircheck, 0, lengthOf(dircheck)-6) + "/";
	}
	conflast = "TileConfiguration" + currentstitch+1 + ".txt";
	if (File.exists(dircheck + conflast)) {
		containsconf = true;
		if (!precheck) {
			for (j=1; j<=currentstitch+1; j++) {
				File.copy(dircheck + "TileConfiguration" + j + ".txt", dirmax[j-1] + "/TileConfiguration.txt");
			}
		}
	} else {
		containsconf = false;
		if (precheck) {
			exit("TileConfiguration file not found in " + dircheck +" , run Denoise_1_processMATL.ipynb first.");
		}
	}
	return containsconf;
}


function create_lowres(dirlowres, name) {
	run("Divide...", "value=4.000 stack");
	for (i=0; i<3; i++) {
		run("Duplicate...", "duplicate");
		num = 40 + 20 * random("gaussian");
		run("Add Specified Noise...", "stack standard=" + num);
		saveAs("tiff", dirlowres[i] + name);
		close();
	}
}


function getnumslice(dirslice) {
	listslice = getFileList(dirslice);
	opened = false;
	i = 0;
	while (!opened) {
		if (endsWith(listslice[i], ".tif")) {
			open(dirslice + listslice[i]);
			opened = true;
		}
		i++;
	}
	getDimensions(width, height, channels, slices, frames);
	close();
	return slices;
}


function deletedir(dirdel) {
	listdel = getFileList(dirdel);
	for (i = 0; i < listdel.length; i++) {
		x = File.delete(dirdel + listdel[i]);
	}
	x = File.delete(dirdel);
}
