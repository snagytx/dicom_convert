local formats = { dcm = '/dicom_images', jpg = '/jpeg_images' }

convert = {
        delay = 0,
        maxProcesses = 5,

        action = function(inlet)
                local event = inlet.getEvent()
                if event.isdir or
                	event.etype == "Modify"
                	then
                        -- ignores events on dirs
                        inlet.discardEvent(event)
                        return
                end

                -- extract extension and basefilename
                local p    = event.pathname
                local ext  = string.match(p, ".*%.([^.]+)$")
                local base = string.match(p, "(.*)%.[^.]+$")
                log("Normal", "addExclude ."..p)
				inlet.addExclude(p)
                if not formats[ext] then
                        -- an unknown extenion
                        log("Normal", "not doing something on ."..ext)
                        inlet.discardEvent(event)
                        return
                end

                log("Normal", "The file: '"..p.."'. Event Type: '"..event.etype.."'")

                -- autoconvert on create and modify
                if event.etype == "Create" or event.etype == "Modify1" then
                        -- builds one bash command
                        local cmd = ""
                        -- do for all other extensions
                        for k, l in pairs(formats) do
                                if k ~= ext then
                                        log("Normal", "Processing")
                                        -- excludes files to be created, so no
                                        -- followup actions will occur
                                        --log("Normal", "Exclude '"..base.."."..ext.."'")
                                        --inlet.addExclude(base..'.'..ext)
                                        --inlet.addExclude(p)
                                        if cmd ~= ""  then
                                                cmd = cmd .. " && "
                                        end
                                        cmd = cmd..
                                                'dcmj2pnm +oj "'..
                                                event.source..base..'.'..ext..'" "'..l..'/'..
                                                base..'.'..k..'" '
                                end
                        end
                        log("Normal", "Converting '"..p.."'. Command: '"..cmd.."'")
                        spawnShell(event, cmd)
                        return
                end

                -- deletes all formats if you delete one
                if event.etype == "Delete" then
                        -- builds one bash command
                        local cmd = ""
                        -- do for all other extensions
                        for k, l in pairs(formats) do
                                if k ~= ext then
                                        -- excludes files to be deleted, so no
                                        -- followup actions will occur
                                      	inlet.addExclude(base..'.'..ext)
                                        if cmd ~= ""  then
                                                cmd = cmd .. " && "
                                        end
                                        cmd = cmd..
                                                'rm "'..l..'/'..base..'.'..k..
                                                '"'
                                end
                        end
                        log("Normal", "Deleting all "..p..". Command: "..cmd)
                        spawnShell(event, cmd)
                        return
                end

                -- ignores other events.
                inlet.discardEvent(event)
        end,

        -----
        -- Removes excludes when convertions are finished
        --
        collect = function(event, exitcode)
                local p     = event.pathname
                local ext   = string.match(p, ".*%.([^.]+)$")
                local base  = string.match(p, "(.*)%.[^.]+$")
                local inlet = event.inlet

                if event.etype == "Create" or
                   event.etype == "Modify" or
                   event.etype == "Delete"
                then
                	log("Normal", "rmExclude: "..p.."; eventType: "..event.etype.."; exitcode: "..exitcode)
                	inlet.rmExclude(p)
                        -- for k, _ in pairs(formats) do
                        -- 		if k ~= ext then
                        -- 			log("Normal", "RM Exclude '"..base.."."..ext.."'")
                        --         	inlet.rmExclude(base..'.'..ext)
                        --         end
                        -- end
                end
        end,

}

sync{
    convert,
    source="/dicom_images"
}

settings{
        logfile    = "/lsyncd/lsyncd.log",
        statusFile = "/lsyncd/lsyncd.status",
        nodaemon   = true
}

