-- CCBootstrap - By Dusk
-- <https://github.com/XDuskAshes/ccbootstrap/>
-- Intended for use of setting up CraftOS environments
-- MIT License

-- oh http/https how i hate you ever so deeply,
-- please go eat unseasoned drywall with
-- a side of very dry turkey on thanksgiving.
local function getURL(url) -- Check if something is actually a URL. If so, return yes and it's contents.
    local resp = http.get(url)
    if not resp then
        return false
    else
        return true, resp
    end
end

local function download(url,file) -- Get the contents of a URL and output to a file.
    local stat, resp = getURL(url)
    if not stat then
        printError("ccbootstrap: Cannot download from URL: "..url.." - invalid")
    else
        local handle = fs.open(shell.resolve(file),"w")
        handle.write(resp.readAll())
        handle.close()
    end
end

local function clearTable(tbl)
    for k in pairs(tbl) do
        tbl[k] = nil
    end
end

-- grab our 'ccbootstrap.json'
local bootstrapJSON
do
    local JsonConfigHandle = fs.open(shell.resolve("ccbootstrap.json"),"r")
    if not JsonConfigHandle then
        error("ccbootstrap: No ccbootstrap.json present in current directory",0)
    end
    bootstrapJSON = textutils.unserialiseJSON(JsonConfigHandle.readAll())
    JsonConfigHandle.close()
end

print("Name: "..bootstrapJSON.meta.name)
print("Description: "..bootstrapJSON.meta.description)
print("Make startup file:",bootstrapJSON.meta.make_startup)
if not bootstrapJSON.operations then
    error("ccbootstrap: no operations",0)
end

if bootstrapJSON.operations.settings then
    if bootstrapJSON.meta.verbose == true then
        write("Setting and saving settings")
        for sKey, vKey in pairs(bootstrapJSON.operations.settings) do
            write(".")
            settings.set(sKey,vKey)
        end
        print(" set and saved")
    else
        print("Settings")
        for sKey, vKey in pairs(bootstrapJSON.operations.settings) do
            print(sKey,"will be",vKey)
            settings.set(sKey,vKey)
        end
        print("End of settings list - saving")
    end
else
    print("There is no settings operation.")
end

if bootstrapJSON.operations.path then
    if not bootstrapJSON.operations.path.string then
        printError("ccbootstrap: no operations.path.string - please set this.")
    else
        if not bootstrapJSON.operations.path.action then
            printError("ccbootstrap: no operations.path.action - please set this.")
        else
            if bootstrapJSON.operations.path.action == "addto" then
                print("Adding",bootstrapJSON.operations.path.string,"to path")
                shell.setPath(shell.path()..":"..bootstrapJSON.operations.path.string)
            elseif bootstrapJSON.operations.path.action == "rewrite" then
                print("Setting shell path to",bootstrapJSON.operations.path.string)
                shell.setPath(bootstrapJSON.operations.path.string)
            else
                printError("ccbootstrap: invalid path.action: "..bootstrapJSON.operations.path.action)
            end
        end
    end
else
    print("There is no path operation.")
end

local finalPath = shell.path() -- Used later in making startup

if bootstrapJSON.operations.fetch then
    local validRepos = {}
    local validFiles = {}
    local validReposBranches = {}
    local finalURLs = {}
    local threads = {} -- a good teacher taught me how to do parallel in a simple way
    print("Fetch operation found.")
    print("This part may be slow, HTTP/HTTPS is not the fastest thing in the world, especially varying with network.")
    for i, fetchingTable in ipairs(bootstrapJSON.operations.fetch) do
        threads[#threads+1] = function()
                local status, foo = getURL("https://github.com/"..fetchingTable.repo)
                if status then
                    print("Valid URL: "..fetchingTable.repo)
                    status, foo = getURL("https://github.com/"..fetchingTable.repo.."/tree/"..fetchingTable.branch)
                    if not status then
                        if not getURL("https://github.com/"..fetchingTable.repo.."/tree/master/") then
                            printError("ccbootstrap: Skipping "..fetchingTable.repo.."\nNo branch of name '"..fetchingTable.branch.."' exists, and cannot default to 'master'.")
                        else
                            printError("ccbootstrap: No branch of name '"..fetchingTable.branch.."' exists, although 'master' does, so pulling from that.")
                            table.insert(validRepos,fetchingTable.repo)
                            table.insert(validFiles,fetchingTable.file)
                            table.insert(validReposBranches,"master")
                        end
                    else
                        print("Branch of name '"..fetchingTable.branch.."' exists for '"..fetchingTable.repo.."'")
                        table.insert(validRepos,fetchingTable.repo)
                        table.insert(validFiles,fetchingTable.file)
                        table.insert(validReposBranches,fetchingTable.branch)
                    end
                else
                    printError("ccbootstrap: Invalid: "..fetchingTable.repo)
                end
            end
    end
    parallel.waitForAll(table.unpack(threads))
    clearTable(threads)
    if #validRepos < 1 then
        printError("ccbootstrap: No valid repositories.")
    else
        for repoNum,repoName in pairs(validRepos) do
            table.insert(finalURLs,"https://raw.githubusercontent.com/"..repoName.."/refs/heads/"..validReposBranches[repoNum].."/"..validFiles[repoNum])
        end

        for k,v in pairs(finalURLs) do
            threads[#threads+1] = function()
                download(v,validFiles[k])
                if not fs.exists(validFiles[k]) then
                    printError("ccbootstrap: File not downloaded for unknown reason: "..validFiles[k].."\nFrom url: "..v)
                end
            end
        end
        parallel.waitForAll(table.unpack(threads))
        clearTable(threads)
    end
else
    printError("ccbootstrap: No fetch operation.")
end

if type(bootstrapJSON.meta.make_startup) ~= "boolean" then
    printError("ccbootstrap: meta.make_startup MUST be true or false")
else
    if bootstrapJSON.meta.make_startup == true then -- I'm not 100% on how it'd treat just it existing. this is also just because why not
        if not bootstrapJSON.operations.path then
            printError("ccbootstrap: No custom path defined, a generated startup file is unecessary.")
        else
            print("Making /startup.lua")
            local sFile = fs.open("/startup.lua","w")
            sFile.writeLine("-- Generated by ccbootstrap\n-- Date and time: "..os.date("%D %I:%M %p"))
            sFile.writeLine("-- Set the path\nshell.setPath('"..finalPath.."')")
            sFile.close()
            print("Created")
        end
    end
end

print("Bootstrap finished")