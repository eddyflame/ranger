#!/usr/bin/env python
import os
import sys

env = SConscript("godot-cpp/SConstruct")

# For our custom C++ code
env.Append(CPPPATH=["src/"])
sources = Glob("src/*.cpp")

# Define target library name
library_name = "myrpg"

# We output the library to project/bin/
library = env.SharedLibrary(
    "project/bin/lib{}{}{}".format(library_name, env["suffix"], env["SHLIBSUFFIX"]),
    source=sources,
)

Default(library)
