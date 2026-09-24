using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;

namespace SB.SyncStatus
{
    internal static class TrayIcons
    {
        public static Icon Ok;
        public static Icon Busy;
        public static Icon Error;

        public static void Ensure()
        {
            if (Ok != null)
                return;
            Ok = Make(Color.FromArgb(40, 167, 69));
            Busy = Make(Color.FromArgb(255, 193, 7));
            Error = Make(Color.FromArgb(220, 53, 69));
        }

        public static Icon ForLevel(StatusLevel level)
        {
            Ensure();
            if (level == StatusLevel.Ok)
                return Ok;
            if (level == StatusLevel.Busy)
                return Busy;
            return Error;
        }

        public static void Dispose()
        {
            if (Ok != null) { Ok.Dispose(); Ok = null; }
            if (Busy != null) { Busy.Dispose(); Busy = null; }
            if (Error != null) { Error.Dispose(); Error = null; }
        }

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        private static extern bool DestroyIcon(IntPtr handle);

        private static Icon Make(Color color)
        {
            using (var bmp = new Bitmap(16, 16))
            using (var g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.Clear(Color.Transparent);
                using (var brush = new SolidBrush(color))
                    g.FillEllipse(brush, 1, 1, 13, 13);
                using (var pen = new Pen(Color.FromArgb(60, 0, 0, 0)))
                    g.DrawEllipse(pen, 1, 1, 13, 13);
                IntPtr handle = bmp.GetHicon();
                try
                {
                    using (var tmp = Icon.FromHandle(handle))
                        return (Icon)tmp.Clone();
                }
                finally
                {
                    DestroyIcon(handle);
                }
            }
        }
    }
}
