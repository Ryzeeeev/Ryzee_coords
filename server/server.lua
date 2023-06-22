
local resource = GetCurrentResourceName()
local defaultEditor = "blocnote" 
local positions = {} 

function ExportToCSV(data, filePath)
    local file = io.open(filePath, "w+")

    if file then
        local headers = "x,y,z,heading\n"
        file:write(headers)

        for _, entry in ipairs(data) do
            local line = string.format("%.2f,%.2f,%.2f,%.2f\n", entry.x, entry.y, entry.z, entry.heading)
            file:write(line)
        end

        file:close()
        print("[Coords System] - Successfully exported coordinates to CSV: " .. filePath)
    else
        print("[Coords System] - Failed to open file for CSV export: " .. filePath)
    end
end


RegisterCommand("exportCoords", function(source, args, rawCommand)
    local fileName = args[1]

    if not fileName then
        print("[Coords System] - Please specify the export format and the file name.")
        return
    end

    local filePath = "exports_ryze_coords/" .. fileName .. ".csv"

    ExportToCSV(positions, filePath)
    print("[Coords System] - Successfully exported coordinates to CSV: " .. filePath .. " Positions saved: " .. #positions)

    positions = {}
end)



function LoadPreferredEditors(resource)
    local fileContent = LoadResourceFile(resource, "preferred_editors.json")
    if fileContent then
        return json.decode(fileContent)
    end
    return nil
end


RegisterCommand("getPos", function(source, args, rawCommands)
    local id = tonumber(args[1])

    if id then
        local player = GetPlayerPed(id)

        if player ~= 0 then
            local coords = GetEntityCoords(player)
            local heading = GetEntityHeading(player)

            local position = { x = coords.x, y = coords.y, z = coords.z, heading = heading }
            table.insert(positions, position) -- Ajouter la position à la table

            local file = io.open("position.txt", "w")

            if file then
                file:write(string.format("vector3(%.2f, %.2f, %.2f)\n", coords.x, coords.y, coords.z))
                file:write(string.format("heading = %.2f\n", heading))
                file:write(string.format("vector4(%.2f, %.2f, %.2f, %.2f)\n", coords.x, coords.y, coords.z, heading))
                file:close()
                print("[Coords System] - Successfully wrote the new coordinates and heading.")
                OpenFileWithEditor("position.txt")
            else
                print("[Coords System] - Failed to open file for writing.")
            end
        else
            print("[Coords System] - Error: This player does not exist!")
        end
    else
        print("[Coords System] - Error: Invalid player ID!")
    end
end)

function OpenFileWithEditor(filePath)
    local editor = GetUserPreferredEditor()
    if editor then
        if editor == "start position.txt" then
            local command = editor
            os.execute(command)
        else
            local command = string.format('start "" "%s" "%s"', editor, filePath)
            os.execute(command)
        end
    else
        print("[Coords System] - Error: No preferred editor found.")
    end
end

function GetUserPreferredEditor()
    local userPreferredEditor = defaultEditor

    local preferredEditors = LoadPreferredEditors(resource)

    if preferredEditors[userPreferredEditor] then
        return preferredEditors[userPreferredEditor]
    else
        print("[Coords System] - Warning: Invalid preferred editor specified.")
        return nil
    end
end

RegisterCommand("changeEditor", function(source, args, rawCommands)
    local editor = args[1]

    if editor then
        editor = editor:lower()
        local preferredEditors = LoadPreferredEditors(resource)
        if preferredEditors[editor] then
            defaultEditor = editor
            print("[Coords System] - Successfully changed the preferred editor to: " .. editor)
        else
            print("[Coords System] - Invalid editor specified.")
        end
    else
        print("[Coords System] - No editor specified.")
    end
end)

RegisterCommand("addEditor", function(source, args, rawCommands)
    local editorName = args[1]
    local editorPath = args[2]

    if editorName and editorPath then
        local preferredEditors = LoadPreferredEditors(resource)
        preferredEditors[editorName] = editorPath
        SavePreferredEditors(preferredEditors) -- Sauvegarde les éditeurs préférés dans le fichier JSON
        print("[Coords System] - Successfully added the editor: " .. editorName)
    else
        print("[Coords System] - Invalid editor name or path.")
    end
end)

RegisterCommand("listEditors", function(source, args, rawCommands)
    print("[Coords System] - Preferred Editors:")
    for editor, path in pairs(LoadPreferredEditors(resource)) do
        print(editor..": "..path)
    end
end)

RegisterCommand("removeEditor", function(source, args, rawCommands)
    local editorName = args[1]

    if editorName then
        local preferredEditors = LoadPreferredEditors(resource)

        if preferredEditors[editorName] then
            preferredEditors[editorName] = nil
            SavePreferredEditors(preferredEditors)
            print("[Coords System] - Successfully removed the editor: " .. editorName)
        else
            print("[Coords System] - Editor not found: " .. editorName)
        end
    else
        print("[Coords System] - No editor name specified.")
    end
end)

function SavePreferredEditors(editors)
    local fileContent = json.encode(editors)
    SaveResourceFile(resource, "preferred_editors.json", fileContent, -1)
    print("[Coords System] - Preferred editors saved successfully.")
end