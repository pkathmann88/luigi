// Test module status enrichment
process.env.MODULES_PATH = '/home/runner/work/luigi/luigi';
process.env.CONFIG_PATH = '/tmp/test-config';
process.env.LOGS_PATH = '/tmp/test-logs';
process.env.LOG_FILE = '/tmp/test-logs/test-api.log';
process.env.AUDIT_LOG_FILE = '/tmp/test-logs/test-audit.log';
process.env.AUTH_USERNAME = 'test';
process.env.AUTH_PASSWORD = 'test12345678';
process.env.NODE_ENV = 'development';

const moduleService = require('./src/services/moduleService');

async function testModuleStatusEnrichment() {
  console.log('=== Testing Module Status Enrichment ===\n');
  
  try {
    const modules = await moduleService.listModules();
    
    console.log(`Found ${modules.length} modules:\n`);
    
    modules.forEach(m => {
      console.log(`Module: ${m.name}`);
      console.log(`  Category: ${m.category}`);
      console.log(`  Path: ${m.path}`);
      console.log(`  Status: ${m.status || 'not set'}`);
      console.log(`  PID: ${m.pid || 'N/A'}`);
      console.log('');
    });
    
    // Check if status is being added
    const hasStatus = modules.every(m => m.status !== undefined);
    console.log(`✓ All modules have status field: ${hasStatus}`);
    
    return hasStatus;
  } catch (err) {
    console.error('Error:', err.message);
    return false;
  }
}

testModuleStatusEnrichment().then(success => {
  process.exit(success ? 0 : 1);
});
