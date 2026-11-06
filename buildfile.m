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

meta = jsondecode(fileread(fullfile(context.Plan.RootFolder, 'codemeta.json')));
url = meta.softwareRequirements{1};

pkg = websave('gemini3d.mltbx', url);
matlab.addons.toolbox.installToolbox(pkg);

end


function checkTask(context)
root = context.Plan.RootFolder;

c = codeIssues(root + ["/test", "/+gemini3d"]);

if isempty(c.Issues)
  fprintf('%d files checked OK with %s under %s\n', numel(c.Files), c.Release, root)
else
  disp(c.Issues)
  error("Errors found in " + join(c.Issues.Location, newline))
end

end
