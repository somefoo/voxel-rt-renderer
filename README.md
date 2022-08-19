# voxel-rt

An interactive volume renderer. Supporting easily programmable shaders with support for transpancy, reflectivity (controllable with rougness), depth blur...

This renderer focuses on rendering scenes interactively. OpenCL is used for this, ensure you have a GPU for interactive results!

![Peek 2022-08-20 01-03](https://user-images.githubusercontent.com/50917034/185717616-f295d057-c765-4a92-a032-02b7ab737f0e.gif)

## How to build
1. Clone project (with submodules!)
2. Go into project folder
3. `mkdir build`
4. `cmake ..`
5. `make -j4`

## How to run
1. `./run-voxel-rt path/to/nrrd_file.nrrd path/to/background.{dng,png,jpg,...}`

# More Example Images
<img src="https://user-images.githubusercontent.com/50917034/185715979-d749b8b1-4076-40a6-82cd-52497d9764e8.png" width="400">
<img src="https://user-images.githubusercontent.com/50917034/185715981-f2ef672f-7c19-4196-a80d-1341b60e99b5.png" width="400">
<img src="https://user-images.githubusercontent.com/50917034/185715983-0d96492b-654a-4f76-bb8f-baeaf6f1f3ff.png" width="400">
<img src="https://user-images.githubusercontent.com/50917034/185715985-07f10908-11af-4419-95df-c9aa8ee5c68b.png" width="400">
<img src="https://user-images.githubusercontent.com/50917034/185715988-8cf09305-7cf7-4500-9d6e-0af85307bb54.png" width="400">
<img src="https://user-images.githubusercontent.com/50917034/185715994-ea1a5f42-949a-4947-9515-1894c859940f.png" width="400">
<img src="https://user-images.githubusercontent.com/50917034/185715995-9920eec1-9a87-4776-be30-394a182fa31a.png" width="400">


