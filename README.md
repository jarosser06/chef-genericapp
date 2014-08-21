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
#### genericapp::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['genericapp']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

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
Authors: TODO: List authors
