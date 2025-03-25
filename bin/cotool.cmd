::/*#! 2> /dev/null                                   #
@ 2>/dev/null # 2>nul & echo off & goto BOF           #
if [ -z "${SIREUM_HOME}" ]; then                      #
  echo "Please set SIREUM_HOME env var"               #
  exit -1                                             #
fi                                                    #
exec "${SIREUM_HOME}/bin/sireum" slang run "$0" "$@"  #
:BOF
setlocal
if not defined SIREUM_HOME (
  echo Please set SIREUM_HOME env var
  exit /B -1
)
"%SIREUM_HOME%\bin\sireum.bat" slang run %0 %*
exit /B %errorlevel%
::!#*/
// #Sireum

import org.sireum._

val home = Os.slashDir.up.canon

if (Os.cliArgs.size != 1) {
  println("Usage: <file>")
  Os.exit(0)
}

var seen = HashSet.empty[String]

def rec(dir: Os.Path, f: Os.Path): Unit = {
  if (seen.contains(f.string)) {
    return
  }
  seen = seen + f.string
  val r = proc"otool -L $f".runCheck()
  for (line <- ops.StringOps(r.out).cisLineStream.drop(1)) {
    val i = ops.StringOps.indexOfFrom(line, '(', 0)
    val lib = Os.path(ops.StringOps(ops.StringOps.substring(line, 0, i)).trim)
    if (lib.exists) {
      val dep = dir / lib.name
      println(s"Co-locating $lib to $dep in $f")
      if (!dep.exists) {
        lib.copyOverTo(dep)
      }
      proc"install_name_tool -change $lib @executable_path/${dep.name} $f".runCheck()
      proc"codesign --force -s - $dep".runCheck()
      rec(dir, dep)
    }
  }
}

val f = Os.path(Os.cliArgs(0))
rec(f.up.canon, f)
