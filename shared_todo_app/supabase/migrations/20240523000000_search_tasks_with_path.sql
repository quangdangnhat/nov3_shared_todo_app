CREATE OR REPLACE FUNCTION search_tasks_with_path(search_term TEXT)
RETURNS TABLE (
    -- Colonne per compatibilit con Task.fromMap
    id UUID,
    folder_id UUID,    title TEXT,
    "desc" TEXT,
    priority TEXT,
    status TEXT,
    start_date TIMESTAMPTZ,
    due_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    -- Colonne extra per la UI della ricerca
    list_id UUID,
    list_name TEXT,
    folder_path TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE folder_paths AS (
        SELECT
            f.id,
            f.todo_list_id,
            f.title,
            f.title::text AS path
        FROM folders f
        WHERE f.parent_id IS NULL
        UNION ALL
        SELECT
            f.id,
            f.todo_list_id,
            f.title,
            fp.path || ' / ' || f.title
        FROM folders f
        JOIN folder_paths fp ON f.parent_id = fp.id
    )
    SELECT
        t.id,
        t.folder_id,
        t.title,
        t.desc,
        t.priority,
        t.status,
        t.start_date,
        t.due_date,
        t.created_at,
        t.updated_at,
        fp.todo_list_id AS list_id,
        tl.title AS list_name,
        COALESCE(fp.path, 'Home') AS folder_path
    FROM tasks t
    JOIN folders f ON t.folder_id = f.id
    LEFT JOIN folder_paths fp ON t.folder_id = fp.id
    LEFT JOIN todo_lists tl ON fp.todo_list_id = tl.id -- Join per ottenere il nome della lista
    WHERE
        fp.todo_list_id IN (
            SELECT p.todo_list_id
            FROM participations p
            WHERE p.user_id = auth.uid()
        )
        AND t.title ILIKE '%' || search_term || '%';
END;
$$;
