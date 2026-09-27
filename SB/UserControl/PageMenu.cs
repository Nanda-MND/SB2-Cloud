using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace SB
{
    public partial class PageMenu : UserControl
    {
        public delegate void MouseSelectedEventHandler(object sender, EventArgs e);
        public event MouseSelectedEventHandler MouseSelected;

        private bool a_Selected = false;

        private Color activeColor = Color.FromArgb(130, 60, 180);
        private Color defaultColor = Color.Transparent;
        private Image mouseEnterImage = Properties.Resources.Menu;
        private Color defaultForeColor = Color.Black;

        public PageMenu()
        {
            InitializeComponent();
            lblMenu.Text = this.Name;
        }

        /// <summary>
        /// background color when selected
        /// </summary>
        public Color ActiveColor
        {
            get { return activeColor; }
            set { activeColor = value; }
        }

        /// <summary>
        /// default background color
        /// </summary>
        public Color DefaultColor
        {
            get { return defaultColor; }
            set { defaultColor = value; }
        }

        /// <summary>
        /// menu caption
        /// </summary>
        public string Caption
        {
            get
            {
                return lblMenu.Text;
            }
            set
            {
                lblMenu.Text = value;
            }
        }

        /// <summary>
        /// menu font
        /// </summary>
        public Font TextFont
        {
            get
            {
                return lblMenu.Font;
            }
            set
            {
                lblMenu.Font = value;
            }
        }

        public Color TextColor
        {
            set
            {
                lblMenu.ForeColor = value;
            }
        }

        /// <summary>
        /// set background color when menu selected
        /// </summary>
        [DefaultValue(false)]
        public bool Selected
        {
            get
            {
                return a_Selected;
            }
            set
            {
                a_Selected = value;
                if (!a_Selected)
                {
                    this.BackColor = defaultColor;
                }
                else
                {
                    this.BackColor = activeColor;
                }
            }
        }

        private void lblMenu_MouseClick(object sender, MouseEventArgs e)
        {
            if (e.Button == System.Windows.Forms.MouseButtons.Left)
            {
                Selected = true;
                this.BackColor = activeColor;
                if (MouseSelected != null)
                    MouseSelected(this, new EventArgs());
            }
        }

        private void lblMenu_MouseEnter(object sender, EventArgs e)
        {
            this.BackgroundImage = mouseEnterImage;
        }

        private void lblMenu_MouseLeave(object sender, EventArgs e)
        {
            this.BackgroundImage = null;
        }

        protected override void OnPaint(PaintEventArgs pe)
        {
            base.OnPaint(pe);
        }
    }
}
