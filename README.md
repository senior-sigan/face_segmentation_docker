# Face Segmentation Docker

1. Download https://download.nvidia.com/XFree86/Linux-x86_64/ and save as `nvidia-driver.run`.

`nvidia_version=$(cat /proc/driver/nvidia/version | head -n 1 | awk '{ print $8 }')`

## How to use

You can run bash `nvidia-docker run -it sigan/face-segmentation bash` and work with the model as described in the original [face_segmentation repo](https://github.com/YuvalNirkin/face_segmentation).