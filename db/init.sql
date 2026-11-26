CREATE TABLE IF NOT EXISTS releases (
  id SERIAL PRIMARY KEY,
  version VARCHAR(50) NOT NULL,
  commit_sha VARCHAR(64) NOT NULL,
  stage VARCHAR(50) NOT NULL DEFAULT 'EKS Rollout',
  status VARCHAR(10) NOT NULL DEFAULT 'PASSED'
    CHECK (status IN ('PASSED', 'BLOCKED', 'FAILED')),
  notes VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO releases (version, commit_sha, stage, status, notes)
SELECT * FROM (VALUES
  ('v1.0.0', '027cb994', 'Trivy + ECR', 'PASSED', 'Zero CRITICAL CVEs; pushed to private ECR'),
  ('v1.0.1', '8f41c209', 'EKS Rollout', 'PASSED', 'Rolling update healthy across private-subnet nodes')
) AS v(version, commit_sha, stage, status, notes)
WHERE NOT EXISTS (SELECT 1 FROM releases);