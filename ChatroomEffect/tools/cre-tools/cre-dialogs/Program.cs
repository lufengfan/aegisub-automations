﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows.Forms;

namespace SamLu.Cre.Dialogs
{
    static class Program
    {
        /// <summary>
        /// 应用程序的主入口点。
        /// </summary>
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            MainForm mainForm = new MainForm();
            if (mainForm.ShowDialog() == DialogResult.OK)
            {
                
            }
        }
    }
}
