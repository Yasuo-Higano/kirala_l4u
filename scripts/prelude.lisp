; dummy

(defn get-env (name)
    (str "env-of-" name)
)

(shared-put "external" (fn (x) (get-env x)))


(defn test-mustache()
    (let [
        template """"{{a}}",'{{b}}'"""
        table {"a" "Alpha" "b" "Beta"}
        compiled_template (template-compile template)
        result (template-render compiled_template table)
    ]
    result))