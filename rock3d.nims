switch("nimcache", "src/nimcache")

task build, "Build the editor":
  setCommand("c", "src/rocked")
  switch("out", "rocked")
