import Foundation
@main enum InstallationTests {
 static func main() throws {
  let fm=FileManager.default,root=fm.temporaryDirectory.appendingPathComponent("maf-install-\(UUID())")
  try fm.createDirectory(at:root,withIntermediateDirectories:true);defer {try? fm.removeItem(at:root)}
  let app=root.appendingPathComponent("Sample.app"),launcher=app.appendingPathComponent("Contents/MacOS/maf")
  try fm.createDirectory(at:launcher.deletingLastPathComponent(),withIntermediateDirectories:true)
  try Data("test fixture".utf8).write(to:launcher);try fm.setAttributes([.posixPermissions:0o700],ofItemAtPath:launcher.path)
  func collision(_ bin:URL) throws {do {try CLIInstallation.install(app:app,bin:bin);preconditionFailure("collision should fail")} catch {precondition((error as? BridgeError)?.code=="already_exists")}}
  let bin=root.appendingPathComponent("bin")
  try CLIInstallation.install(app:app,bin:bin);try CLIInstallation.install(app:app,bin:bin)
  precondition(CLIInstallation.isInstalled(app:app,bin:bin))
  for name in ["maf","aft"] {let target=try fm.destinationOfSymbolicLink(atPath:bin.appendingPathComponent(name).path);precondition(target==launcher.path)}
  print("PASS Both aliases install and repeat idempotently")
  let conflict=root.appendingPathComponent("conflict");try fm.createDirectory(at:conflict,withIntermediateDirectories:true)
  let file=conflict.appendingPathComponent("aft"),data=Data("unrelated command".utf8);try data.write(to:file)
  try collision(conflict);precondition(!fm.fileExists(atPath:conflict.appendingPathComponent("maf").path));let preserved=try Data(contentsOf:file);precondition(preserved==data)
  print("PASS Preflight prevents partial installation and preserves unrelated aft")
  let dangling=root.appendingPathComponent("dangling");try fm.createDirectory(at:dangling,withIntermediateDirectories:true)
  try fm.createSymbolicLink(atPath:dangling.appendingPathComponent("maf").path,withDestinationPath:"/nonexistent/unrelated")
  try collision(dangling);let target=try fm.destinationOfSymbolicLink(atPath:dangling.appendingPathComponent("maf").path);precondition(target=="/nonexistent/unrelated")
  print("PASS Dangling unrelated symlink is preserved")
  let missing=root.appendingPathComponent("missing-bin")
  do {try CLIInstallation.install(app:root.appendingPathComponent("Missing.app"),bin:missing);preconditionFailure("missing launcher")}catch {precondition(!fm.fileExists(atPath:missing.path))}
  print("PASS Missing bundled launcher makes no changes")
  print("4 installer scenarios passed")
 }
}
