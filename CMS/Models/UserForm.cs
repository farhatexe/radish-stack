﻿using System;

namespace CMS.Models
{
    public class UserForm
    {
        public UserForm()
        {
             Image = "";
        }
        public Guid   Id { get; set; }
        public string Name { get; set; }
        
        public string UserName { get; set; }
        public string Password { get; set; }
        public string Phone { get; set; }
        public string Image { get; set; }
        public int Role { get; set; }
        public string Email { get; set; }
    }
}