using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

namespace LegadoReader
{
    internal static class Launcher
    {
        [STAThread]
        private static void Main()
        {
            var baseDir = AppDomain.CurrentDomain.BaseDirectory;
            var java = Path.Combine(baseDir, "runtime", "bin", "javaw.exe");
            var jar = Path.Combine(baseDir, "app", "reader.jar");

            if (!File.Exists(java) || !File.Exists(jar))
            {
                MessageBox.Show(
                    "安装文件不完整，请重新安装。\n缺少：" + (!File.Exists(java) ? java : jar),
                    "阅读",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return;
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = java,
                Arguments = "-Dreader.app.showUI=true -Dfile.encoding=UTF-8 -jar \"" + jar + "\"",
                WorkingDirectory = baseDir,
                UseShellExecute = false
            };

            try
            {
                Process.Start(startInfo);
            }
            catch (Exception ex)
            {
                MessageBox.Show("启动失败：" + ex.Message, "阅读", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
