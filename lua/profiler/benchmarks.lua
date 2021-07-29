
local directory = "/lua/profiler/benchmarks"

local FunctionsToExclude = {
      "import"
    , "ComputePoint"
}

function RunToSync()
    
    -- capture in local scope
    local import = import
    local type = type 

    -- find all benchmark files
    local files = DiskFindFiles(directory, "*.lua")
    
    local results = { }

    -- import them
    for k, file in files do 

        results[file] = { }

        -- load in the benchmark and run them
        local benchmark = import(file)
        for e, element in benchmark do 
            if not table.find(FunctionsToExclude, e) then 
                if type(element) == "function" then 

                    LOG("Running " .. e .. " of file " .. file)
                    results[file][e] = {
                          Time = element()
                        , Code = debug.listcode(element)
                    }

                end
            end
        end
    end

    -- send it to the ui
    Sync.Profiler = Sync.Profiler or { }
    Sync.Profiler.Benchmarks = results
end