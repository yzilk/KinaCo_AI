#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { KinaCoStack } from '../lib/kinaco-stack';

const app = new cdk.App();
new KinaCoStack(app, 'KinaCoStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: 'ap-northeast-1',
  },
});
