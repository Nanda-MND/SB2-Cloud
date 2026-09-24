using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Threading;
using System.Windows.Forms;

namespace SB.SyncStatus
{
    internal sealed class TrayApp : ApplicationContext
    {
        private readonly NotifyIcon _tray;
        private readonly System.Windows.Forms.Timer _timer;
        private readonly StatusForm _form;
        private readonly ToolStripMenuItem _startupItem;
        private StatusLevel _lastLevel = (StatusLevel)(-1);
        private bool _refreshing;

        public TrayApp()
        {
            TrayIcons.Ensure();
            StartupHelper.Ensure();

            _form = new StatusForm();
            _form.PlaceNearTray();
            var unusedHandle = _form.Handle;
            if (unusedHandle == IntPtr.Zero)
                throw new InvalidOperationException("Status window handle was not created.");

            _startupItem = new ToolStripMenuItem("Start with Windows");
            _startupItem.Click += (s, e) =>
            {
                bool next = !_startupItem.Checked;
                StartupHelper.SetEnabled(next);
                _startupItem.Checked = StartupHelper.IsEnabled();
            };

            var menu = new ContextMenuStrip();
            menu.Opening += (s, e) => _startupItem.Checked = StartupHelper.IsEnabled();
            menu.Items.Add("Open status", null, (s, e) => ShowStatus());
            menu.Items.Add("Refresh now", null, (s, e) => Refresh(true));
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add(_startupItem);
            menu.Items.Add("Open SyncAgent.log", null, (s, e) => OpenLog());
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add("Exit", null, (s, e) => ExitApp());

            _tray = new NotifyIcon
            {
                Icon = TrayIcons.Error,
                Text = "SB Sync",
                Visible = true,
                ContextMenuStrip = menu
            };
            _tray.MouseClick += (s, e) =>
            {
                if (e.Button == MouseButtons.Left)
                    ShowStatus();
            };

            _timer = new System.Windows.Forms.Timer { Interval = 4000 };
            _timer.Tick += (s, e) => Refresh(false);
            _timer.Start();

            Refresh(true);
        }

        private void ShowStatus()
        {
            Refresh(true);
            _form.PlaceNearTray();
            _form.Show();
            _form.Activate();
        }

        private void Refresh(bool balloonOnError)
        {
            if (_refreshing)
                return;
            _refreshing = true;
            ThreadPool.QueueUserWorkItem(_ =>
            {
                StatusSnapshot snap;
                try
                {
                    snap = StatusReader.Read();
                }
                catch (Exception ex)
                {
                    snap = StatusSnapshot.Fail(ex.Message);
                }

                try
                {
                    if (_tray != null && _form != null && !_form.IsDisposed)
                    {
                        _form.BeginInvoke(new Action(() => Apply(snap, balloonOnError)));
                    }
                }
                catch
                {
                    _refreshing = false;
                }
            });
        }

        private void Apply(StatusSnapshot snap, bool balloonOnError)
        {
            try
            {
                _tray.Icon = TrayIcons.ForLevel(snap.Level);
                _tray.Text = Truncate(snap.Tooltip, 63);
                _form.Apply(snap);

                bool becameError = snap.Level == StatusLevel.Error && _lastLevel != StatusLevel.Error;
                _lastLevel = snap.Level;
                if (balloonOnError && becameError)
                {
                    _tray.BalloonTipTitle = "SB Sync";
                    _tray.BalloonTipText = Truncate(snap.Headline + " — " + (snap.LastError ?? snap.Detail), 200);
                    _tray.BalloonTipIcon = ToolTipIcon.Error;
                    _tray.ShowBalloonTip(4000);
                }
            }
            finally
            {
                _refreshing = false;
            }
        }

        private static void OpenLog()
        {
            string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "SyncAgent.log");
            if (!File.Exists(path))
            {
                MessageBox.Show("Log not found:\n" + path, "SB Sync Status",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            Process.Start(new ProcessStartInfo
            {
                FileName = path,
                UseShellExecute = true
            });
        }

        private void ExitApp()
        {
            _timer.Stop();
            _tray.Visible = false;
            _tray.Dispose();
            TrayIcons.Dispose();
            if (!_form.IsDisposed)
                _form.Dispose();
            ExitThread();
        }

        private static string Truncate(string text, int max)
        {
            if (string.IsNullOrEmpty(text) || text.Length <= max)
                return text ?? "";
            return text.Substring(0, max - 1);
        }
    }
}
