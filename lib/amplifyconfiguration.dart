
import 'package:amplify_flutter/amplify_flutter.dart';

final amplifyConfig = AmplifyOutputs.fromJson({
  'version': '1',
  'auth': {
    'aws_region': 'ap-southeast-2',
    'user_pool_id': 'ap-southeast-2_GF2dV4OsV',
    'user_pool_client_id': '1549mv47ecgn7dq27dsee4mj7b',
    'oauth': {
      'identity_providers': ['GOOGLE'],
      'domain':
          'insol8-auth-dev.auth.ap-southeast-2.amazoncognito.com',
      'scopes': ['openid', 'email', 'profile'],
      'redirect_sign_in_uri': [
        'com.insol8.mobile://callback/',
      ],
      'redirect_sign_out_uri': [
        'com.insol8.mobile://signout/',
      ],
      'response_type': 'code',
    },
  },
});
