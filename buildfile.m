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

mat_gemini = fullfile(context.Plan.RootFolder, "mat_gemini");
matbf = fullfile(mat_gemini, "buildfile.m");

if ~isfile(matbf)
  ok = system("git -C " + context.Plan.RootFolder + " submodule update --init --recursive");
  assert(ok == 0, "Failed to update MatGemini Git submodule");
end


buildtool("-buildFile", mat_gemini, "setup")

end
