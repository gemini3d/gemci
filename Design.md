# Design notes

A particular aspect of the GemCI project is that there are two ExternalProjects for Gemini3D.
This is because we want to have a "Debug" Gemini3D that has array bounds checking enabled among other additional checks too onerous for general "Release" users.
This might seem like what Ninja Multi-Config is for, but Ninja 1.10 fork bombs when trying to use with ExternalProject.
To avoid this problem and in general to avoid requiring users use Ninja, we instead use a "Debug" Gemini3D ExternalProject and a "Release" Gemini3D ExternalProject.
