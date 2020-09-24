1. Go to https://lmb.informatik.uni-freiburg.de/resources/opensource/unet/

2. Download https://lmb.informatik.uni-freiburg.de/resources/opensource/unet/caffe_unet_package_18.04_gpu_cuda10_cudnn7.tar.gz.

3. Extract to `/home/eroglulab/caffe-unet`

4. Install the latest nVidia driver.

5. Install miniconda and install `cudatoolkit=10.0 cudnn=7` to base.

6. Install Fiji and install the U-Net plugin as stated on the website.

7. Due to some path issues, we need to call `caffe_unet` through an SSH tunnel. Run the following.

	```
	sudo apt install openssh-server
	ssh-keygen -t rsa -b 4096
	cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
	```

8. Add the following to `~/.bashrc`

	```
	PATH="$PATH:/home/eroglulab/caffe_unet/bin"
	LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/home/eroglulab/caffe_unet/lib:/home/eroglulab/caffe_unet/extlib:/home/eroglulab/miniconda3/lib"

	export PATH
	export LD_LIBRARY_PATH
	```

9. Add the following to `~/.bash_profile`.

	```
	source ~/.bashrc
	```