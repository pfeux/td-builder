# escape=`

# Use a specific tagged image.
ARG FROM_IMAGE=mcr.microsoft.com/windows/servercore:ltsc2019
FROM ${FROM_IMAGE} as build

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

# Copy our Install script.
COPY Install.cmd C:\TEMP\

# Download collect.exe in case of an install failure.
ADD https://aka.ms/vscollect.exe C:\TEMP\collect.exe

# Use the latest release channel. For more control, specify the location of an internal layout.
ARG CHANNEL_URL=https://aka.ms/vs/15/release/channel
ADD ${CHANNEL_URL} C:\TEMP\VisualStudio.chman

RUN curl -SL --output vs_buildtools.exe https://aka.ms/vs/15/release/vs_buildtools.exe

RUN call C:\TEMP\Install.cmd vs_buildtools.exe --quiet --wait --norestart --installPath C:\BuildTools --channelUri C:\TEMP\VisualStudio.chman --installChannelUri C:\TEMP\VisualStudio.chman --add Microsoft.VisualStudio.Workload.MSBuildTools --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.Windows81SDK --add Microsoft.VisualStudio.Component.VC.140 --add Microsoft.Component.VC.Runtime.UCRTSDK

RUN del /q vs_buildtools.exe

# Define the entry point for the Docker container.
# This entry point starts the developer command prompt and launches the PowerShell shell.
RUN ["C:\\BuildTools\\Common7\\Tools\\VsDevCmd.bat"]

# Install Choco
RUN powershell Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install cmake
RUN choco install -y cmake --installargs 'ADD_CMAKE_TO_PATH=User'
RUN cmake

# Install git
RUN choco install -y git 
RUN git --version

# Set telegram folder
WORKDIR /telegram

# Clone the td repo and build it
RUN git clone https://github.com/tdlib/td.git
WORKDIR /telegram/td

# Install pre-requisite 
RUN git clone https://github.com/Microsoft/vcpkg.git
WORKDIR /telegram/td/vcpkg
RUN bootstrap-vcpkg.bat
RUN vcpkg.exe install gperf:x64-windows openssl:x64-windows zlib:x64-windows

WORKDIR /telegram/td

# Create build folder
RUN mkdir build
WORKDIR /telegram/td/build

# Execute cmake to build library
RUN cmake -A x64 -DCMAKE_INSTALL_PREFIX:PATH=../tdlib -DTD_ENABLE_DOTNET=ON -DCMAKE_TOOLCHAIN_FILE:FILEPATH=../vcpkg/scripts/buildsystems/vcpkg.cmake ..
RUN cmake --build . --target install --config Release

# Create Lib folder to transfer the Release build
WORKDIR /telegram/td
RUN mkdir Lib

WORKDIR /telegram/td/Lib
RUN mkdir Release

# Copy Release build to Release folder in Lib
RUN cp /telegram/td/tdlib /telegram/td/Lib/Release

RUN Powershell Remove-Item /telegram/td/tdlib -Force -Recurse -ErrorAction SilentlyContinue

# Build Debug build
WORKDIR /telegram/td/build
RUN cmake --build . --target install --config Debug

# Copy Debug build to Debug folder in Lib
WORKDIR /telegram/td/Lib
RUN mkdir Debug

RUN cp /telegram/td/tdlib /telegram/td/Lib/Debug

FROM hello-world as final
COPY build:/telegram/td/Lib /telegram/td/Lib
