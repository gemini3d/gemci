function plan = buildfile
plan = buildplan(localfunctions);
plan.DefaultTasks = "setup";
assert(~isMATLABReleaseOlderThan("R2024b"), "GemCI MatGemini requires Matlab R2024b or newer")

% most simulations use env var GEMINI_CIROOT
% several gigabytes of simulation data are stored there while running CI

if isempty(getenv("GEMINI_CIROOT"))
  setenv("GEMINI_CIROOT", "~/gemci")
end

end


function setupTask(context)
% configure paths to work with MatGemini

gemini_matlab = getenv("MATGEMINI");
if isempty(gemini_matlab)
  gemini_matlab = fullfile(context.Plan.RootFolder, "../mat_gemini");
end

mat_gemini = fullfile(gemini_matlab, "buildfile.m");

assert(isfile(mat_gemini), "please set the environment variable MATGEMINI to the path to the mat_gemini project directory. See README.md for how to get mat_gemini.")

buildtool("-buildFile", mat_gemini)

end
