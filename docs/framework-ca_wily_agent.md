# CA Wily Agent Framework
The CA Wily Agent Framework causes an application to be automatically configured to work with a bound [CA Wily service][].

<table>
  <tr>
    <td><strong>Detection Criterion</strong></td><td>Existence of a single bound CA Wily service.
      <ul>
        <li>Existence of a CA Wily service is defined as the <a href="http://docs.cloudfoundry.org/devguide/deploy-apps/environment-variable.html#VCAP-SERVICES"><code>VCAP_SERVICES</code></a> payload containing a service who's name, label or tag has <code>ca-wily</code> as a substring.</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td><strong>Tags</strong></td>
    <td><tt>ca-wily-agent=&lt;version&gt;</tt></td>
  </tr>
</table>
Tags are printed to standard output by the buildpack detect script

## User-Provided Service (Optional)
Users may optionally provide their own CA Wily service. A user-provided CA Wily service must have a name or tag with `ca-wily` in it so that the CA Wily Agent Framework will automatically configure the application to work with the service.

The credential payload of the service may contain the following entries:

| Name | Description
| ---- | -----------
| `agent-name` | The name that should be given to this instance of the CA Wily agent
| `host-name` | The host name of the CA Wily server
| `ssl` | Should SSL be used to communicate with the CA Wily server
| `port` | The port of the CA Wily server

## Configuration
For general information on configuring the buildpack, refer to [Configuration and Extension][].

The framework can be configured by modifying the [`config/ca_wily_agent.yml`][] file in the buildpack fork.  The framework uses the [`Repository` utility support][repositories] and so it supports the [version syntax][] defined there.

| Name | Description
| ---- | -----------
| `repository_root` | The URL of the CA Wily Agent repository index ([details][repositories]).
| `version` | The version of CA Wily Agent to use.

### Additional Resources
The framework can also be configured by overlaying a set of resources on the default distribution.  To do this, add files to the `resources/ca_wily_agent` directory in the buildpack fork.  For example, to override the default profile add your custom profile to `resources/ca_wily_agent/`.

[Configuration and Extension]: ../README.md#configuration-and-extension
[`config/ca_wily_agent.yml`]: ../config/ca_wily_agent.yml
[CA Wily service]: http://www.ca.com/us/opscenter/ca-application-performance-management.aspx
[repositories]: extending-repositories.md
[version syntax]: extending-repositories.md#version-syntax-and-ordering
