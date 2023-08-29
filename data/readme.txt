In order to create test-data, you have to change `path_to_project` 
into your current project directory for example `F:\myProject`.
Also, you have to modify a file `import-Data-plan.json`,
change path in all references into ["path_to_project\\data\\object.json"]

example of changes into the `import-Data-plan.json` file:

"F:\\myProject\\data\\TC_Activities.json"

example of run:

Windows: sfdx force:data:tree:import -p data\\import-Data-plan.json -u <alias>
MacOS X: sfdx force:data:tree:import -p data/import-Data-plan.json -u <alias>


