-- ============================================
-- 07 - Configurar Permissões Restritivas
-- ============================================
-- Descrição: Define permissões de segurança para a tabela de auditoria
--            - Apenas INSERT e SELECT são permitidos
--            - UPDATE e DELETE são bloqueados
-- Execução: Uma vez no banco operacional
-- Nota: Ajuste os roles conforme seu ambiente
-- ============================================

-- Revogar todas as permissões padrão
REVOKE ALL ON audit_log FROM PUBLIC;

-- Permitir apenas INSERT para aplicação
-- GRANT INSERT ON audit_log TO app_user;  -- Descomentar e ajustar o nome do role

-- Permitir SELECT apenas para roles específicos (auditores, admins)
-- GRANT SELECT ON audit_log TO auditor_role;  -- Descomentar e ajustar
-- GRANT SELECT ON audit_log TO admin_role;    -- Descomentar e ajustar

-- Garantir que a função de trigger pode inserir
-- (já garantido por SECURITY DEFINER na função)

-- Bloquear UPDATE e DELETE explicitamente
-- Isso será reforçado pelo trigger de proteção no próximo script

-- Comentários
COMMENT ON TABLE audit_log IS 'Tabela de auditoria - SOMENTE INSERT e SELECT permitidos';

-- Verificação das permissões
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges
WHERE table_name = 'audit_log'
ORDER BY grantee, privilege_type;

SELECT 'Permissões configuradas com sucesso!' as status;
SELECT '⚠️  IMPORTANTE: Ajuste os GRANT statements conforme os roles do seu ambiente!' as aviso;

/*
INSTRUÇÕES PARA CONFIGURAÇÃO:

1. Identifique os roles/usuários do seu sistema:
   SELECT rolname FROM pg_roles WHERE rolcanlogin ORDER BY rolname;

2. Ajuste os GRANT statements acima conforme necessário:
   - Role da aplicação: precisa de INSERT
   - Role de auditoria: precisa de SELECT
   - Role de admin: pode precisar de SELECT

3. Exemplo completo:
   GRANT INSERT ON audit_log TO app_backend;
   GRANT SELECT ON audit_log TO auditor, dba, admin;
   GRANT USAGE ON SEQUENCE audit_log_id_seq TO app_backend;
*/
