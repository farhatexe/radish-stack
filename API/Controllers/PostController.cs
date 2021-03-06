﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using Core;
using Core.Repositories;

namespace API.Controllers
{
    public class PostController : ApiController
    {
        // GET: api/Post
        public IEnumerable<Post> Get()
        {
            return Pool.Instance.Posts.GetAll(10);
        }

        // GET: api/Post/5
        public string Get(int id)
        {
            return "value";
        }

        // POST: api/Post
        public void Post([FromBody]string value)
        {
        }

        // PUT: api/Post/5
        public void Put(int id, [FromBody]string value)
        {
        }

        // DELETE: api/Post/5
        public void Delete(int id)
        {
        }
    }
}
