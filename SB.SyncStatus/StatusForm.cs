using System;
using System.Drawing;
using System.Windows.Forms;

namespace SB.SyncStatus
{
    internal sealed class StatusForm : Form
    {
        private readonly Label _headline;
        private readonly Label _agent;
        private readonly Label _cloud;
        private readonly Label _l2c;
        private readonly Label _c2l;
        private readonly Label _dead;
        private readonly Label _conflict;
        private readonly Label _last;
        private readonly Label _error;

        public StatusForm()
        {
            Text = "SB Sync Status";
            FormBorderStyle = FormBorderStyle.FixedToolWindow;
            StartPosition = FormStartPosition.Manual;
            ShowInTaskbar = false;
            MinimizeBox = false;
            MaximizeBox = false;
            ClientSize = new Size(340, 268);
            Font = new Font("Segoe UI", 9f);
            Padding = new Padding(12);
            TopMost = true;

            var layout = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 2,
                RowCount = 9,
                AutoSize = false
            };
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 110));
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));

            _headline = MakeValue(true);
            _agent = MakeValue(false);
            _cloud = MakeValue(false);
            _l2c = MakeValue(false);
            _c2l = MakeValue(false);
            _dead = MakeValue(false);
            _conflict = MakeValue(false);
            _last = MakeValue(false);
            _error = MakeValue(false);
            _error.AutoSize = false;
            _error.Dock = DockStyle.Fill;

            AddRow(layout, 0, "", _headline);
            AddRow(layout, 1, "Agent", _agent);
            AddRow(layout, 2, "Cloud", _cloud);
            AddRow(layout, 3, "L2C pending", _l2c);
            AddRow(layout, 4, "C2L pending", _c2l);
            AddRow(layout, 5, "Dead letter", _dead);
            AddRow(layout, 6, "Conflict", _conflict);
            AddRow(layout, 7, "Last synced", _last);
            AddRow(layout, 8, "Last error", _error);

            for (int i = 0; i < 8; i++)
                layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 24));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));

            Controls.Add(layout);

            FormClosing += (s, e) =>
            {
                if (e.CloseReason == CloseReason.UserClosing)
                {
                    e.Cancel = true;
                    Hide();
                }
            };
        }

        public void PlaceNearTray()
        {
            var area = Screen.PrimaryScreen.WorkingArea;
            Left = area.Right - Width - 8;
            Top = area.Bottom - Height - 8;
        }

        public void Apply(StatusSnapshot snap)
        {
            if (snap == null)
                return;

            _headline.Text = snap.Headline;
            _headline.ForeColor = ColorFor(snap.Level);
            _agent.Text = snap.AgentRunning ? "Running" : "Stopped";
            _agent.ForeColor = snap.AgentRunning ? Color.ForestGreen : Color.Firebrick;
            _cloud.Text = snap.CloudOnline ? "Online" : "Offline";
            _cloud.ForeColor = snap.CloudOnline ? Color.ForestGreen : Color.Firebrick;
            _l2c.Text = snap.L2CPending.ToString();
            _c2l.Text = snap.C2LPending.ToString();
            _dead.Text = snap.DeadLetter.ToString();
            _conflict.Text = snap.Conflict.ToString();
            _last.Text = snap.LastSyncedAt.HasValue
                ? snap.LastSyncedAt.Value.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss")
                : "-";
            _error.Text = string.IsNullOrEmpty(snap.LastError) ? "-" : snap.LastError;
        }

        private static Color ColorFor(StatusLevel level)
        {
            if (level == StatusLevel.Ok)
                return Color.ForestGreen;
            if (level == StatusLevel.Busy)
                return Color.DarkOrange;
            return Color.Firebrick;
        }

        private static Label MakeValue(bool headline)
        {
            return new Label
            {
                AutoSize = true,
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleLeft,
                Font = headline
                    ? new Font("Segoe UI", 12f, FontStyle.Bold)
                    : new Font("Segoe UI", 9f),
                Text = "-"
            };
        }

        private static void AddRow(TableLayoutPanel layout, int row, string caption, Control value)
        {
            var cap = new Label
            {
                Text = caption,
                AutoSize = true,
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleLeft,
                ForeColor = Color.DimGray
            };
            layout.Controls.Add(cap, 0, row);
            layout.Controls.Add(value, 1, row);
        }
    }
}
