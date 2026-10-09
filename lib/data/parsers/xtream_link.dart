// Recognises Xtream Codes links such as
// `http://host:8080/get.php?username=U&password=P&type=m3u_plus`
// so the user can paste one link instead of filling three fields.

class XtreamLink {
  final String serverUrl;
  final String username;
  final String password;

  const XtreamLink({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  static XtreamLink? tryParse(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;
    if (!text.contains('://')) text = 'http://$text';

    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) return null;

    final username = uri.queryParameters['username'];
    final password = uri.queryParameters['password'];
    if (username == null || username.isEmpty || password == null || password.isEmpty) {
      return null;
    }

    final server = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
    return XtreamLink(serverUrl: server, username: username, password: password);
  }
}
