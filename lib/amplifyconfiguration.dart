import 'package:amplify_flutter/amplify_flutter.dart';

final amplifyConfig = AmplifyOutputs.fromJson({
  'version': '1',
  'auth': {
    'aws_region': 'ap-southeast-2',
    'user_pool_id': 'ap-southeast-2_VrajtF200',
    'user_pool_client_id': '4b818vl6p65tdggcftrga0cdku',
    'oauth': {
      'identity_providers': ['GOOGLE'],
      'domain': 'insol8-signin-dev.auth.ap-southeast-2.amazoncognito.com',
      // aws.cognito.signin.user.admin lets Google sign-ins add a mobile
      // number (Cognito's attribute APIs reject tokens without it).
      'scopes': ['openid', 'email', 'profile', 'aws.cognito.signin.user.admin'],
      'redirect_sign_in_uri': ['com.insol8.mobile://callback/'],
      'redirect_sign_out_uri': ['com.insol8.mobile://signout/'],
      'response_type': 'code',
    },
  },
});
