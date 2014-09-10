GenericApp Cookbook
===================
Provides the base resource generic_app to be inherited
by PythonApp, NodeApp, etc.

By itself it has the ability to deploy simple static web apps.

Requirements
------------
#### Distros
- `Ubuntu 12.04`
- `Ubuntu 14.04`
- `CentOS/RHEL 6.5`
- `CentOS/RHEL 7.0`

Resource Provider
-----------------

### generic_app
#### actions

- **deploy** - deploys the app
- **remove** - removes the app(currently not implemented)

#### attributes

- **deploy_key** - deploy key to checkout the app
- **site_names** - other site names or aliases
- **path** - where to actually deploy the site
- **repository** - the git repository to pull the app from
- **revision** - the git revision to use
- **owner** - the owner of the app(defaults to nginx or apache user)
- **group** - the group (defaults to nginx or apache user)
- **error_log** - the error log (defaults to apache or nginx log path)
- **access_log** - the access log (defaults to the apache or nginx log path)
- **web_server** - the web server to use, defaults to apache
- **web_template** - the conf file to use for the site (assumes the caller cookbook is the source)
- **after_checkout** - callback after checkout and before setting up the web server

Ex: See the test cookbook included for an example on how to use the resource provider.

Contributing
------------
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors:: Jim Rosser(jarosser06@gmail.com)

```text
copyright (C) 2014 Jim Rosser

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the “Software”), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
```
