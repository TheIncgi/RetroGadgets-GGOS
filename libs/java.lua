local java = {}

function java.run(jar, vmArgs, args)
    vmArgs = vmArgs or {}
    args = args or {}
    local javaHome = os.getenv"JAVA_HOME" 
    exe = javaHome and javaHome.."/bin/java.exe" or "java"

    return io.popen(exe.." "..table.concat(vmArgs," ")..
        (#vmArgs > 0 and " " or "") ..
        "-jar "..jar..(#args > 0 and " " or "") .. table.concat(args or {}," "), "w")
end

return java