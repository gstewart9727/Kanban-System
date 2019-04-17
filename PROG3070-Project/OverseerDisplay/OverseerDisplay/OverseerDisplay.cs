﻿using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Windows.Forms;

//Filename      :
//Project Name  :
//Programmer    : Gabriel Stewart
//Version Date  :
//Description   :
//Sources		:

namespace OverseerDisplay
{
    public partial class OverseerDisplay : Form
    {
        private bool loop = false;

        public OverseerDisplay()
        {
            InitializeComponent();
        }

        private void OverseerDisplay_Load(object sender, EventArgs e)
        {
            GridView.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.DisplayedCells;
        }

        // Method		: GetData
        // Description	: Saves records returned from executing query passes as parameter
        // Parameters	: string query - query string used to gather data from server
        // Returns		: ArrayList - contains data gathered from server
        private List<object> GetData()
        {
            // Grab connection string from config file
            string constr = System.Configuration.ConfigurationManager.ConnectionStrings["SQL_Connection"].ConnectionString;
            List<object> Results = new List<object>();
            DataTable table = new DataTable();

            // Establish connection to database
            using(SqlConnection con = new SqlConnection(constr))
            {
                // Execute command using query
                using(SqlCommand command = new SqlCommand("SELECT * FROM StationData", con))
                {
                    con.Open(); // Open connection

                    // Execute reader to begin gathering records from db
                    using(SqlDataReader reader = command.ExecuteReader())
                    {
                        // While there are still results to process
                        table.Load(reader);
                        GridView.DataSource = table;
                        GridView.ClearSelection();
                    }
                }
            }
            // Return the gathered data
            return Results;
        }

        // Method		: RunBtn_Click
        // Description	: Starts/Stops thread and updates button for control
        // Parameters	: Generic sender information
        // Returns		: None
        private void RunBtn_Click(object sender, EventArgs e)
        {
            // If the application is currently running an update loop
            if(loop)
            {
                // Shut it off and allow option to start
                RunBtn.Text = "START";
                Refresh.Stop();
                loop = false;
            }
            else
            {
                // Turn it on and allow option to finish
                RunBtn.Text = "STOP";
                Refresh.Start();
                loop = true;
            }
        }

        private void Update_Tick(object sender, EventArgs e)
        {
            GetData();
        }
    }
}