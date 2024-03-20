import argparse
import os

def remove_lisp_comments(text):
    lines = text.split('\n')
    new_lines = []
    for line in lines:
        line = line.split(';')[0]
        new_lines.append(line)
    return '\n'.join(new_lines)


def load_content(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = remove_lisp_comments(content)
    return content

def load_binary(file_path):
    with open(file_path, 'rb') as f:
        content = f.read()
    
    return content

# Erlang ---------------------------------------------------------------------------------------------------------

def escape_for_erlang(text):
    return text.replace('\\', '\\\\').replace('\r', '\\r').replace('\n', '\\n').replace('\t', '\\t').replace('"', '\\"')
    #return text.replace('\\', '\\\\').replace('"', '\\"')

def generate_erlang_source(file_path, resource_name):
    content = load_content(file_path)
    
    escaped_content = escape_for_erlang(content)
    #return f'load_{resource_name}() -> <<"{escaped_content}"/utf8>>.\n'
    return f'load(<<"{resource_name}">>) -> <<"{escaped_content}"/utf8>>;\n\n'

def output_erl(output_path, resources):
    output_content = f'-module({os.path.basename(output_path).split(".")[0]}).\n-compile(export_all).\n\n'
    for resource in resources:
        resource_name, file_path = resource.split(',')
        output_content += generate_erlang_source(file_path, resource_name)

    output_content += 'load(_) -> undefined.\n'

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(output_content)

# Javascript ---------------------------------------------------------------------------------------------------------

def escape_for_js(text):
    return text.replace('\\', '\\\\').replace('\r', '\\r').replace('\n', '\\n').replace('\t', '\\t').replace('"', '\\"')

def generate_js_source(file_path, resource_name):
    content = load_content(file_path)
    
    escaped_content = escape_for_js(content)
    return f'        case "{resource_name}":\n            return "{escaped_content}";\n'

def output_js(output_path, resources):
    output_content = f'// {os.path.basename(output_path).split(".")[0]}\n\n'
    output_content += 'export function load(resource_name) {\n'
    output_content += '    switch (resource_name) {\n'

    for resource in resources:
        resource_name, file_path = resource.split(',')
        output_content += generate_js_source(file_path, resource_name)

    output_content += '        default:\n'
    output_content += '            return undefined;\n'
    output_content += '    }\n'
    output_content += '}\n'

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(output_content)

# Dart ---------------------------------------------------------------------------------------------------------

def escape_for_dart(text):
    return text.replace('\\', '\\\\').replace('\r', '\\r').replace('\n', '\\n').replace('\t', '\\t').replace('"', '\\"')

def generate_dart_source(file_path, resource_name):
    content = load_content(file_path)
    escaped_content = escape_for_js(content)
    return f'        case "{resource_name}":\n            return "{escaped_content}";\n'

def generate_dart_source_for_binary(file_path, resource_name):
    binary_data = load_binary(file_path)
    content = ", ".join([str(x) for x in binary_data])

    return f'        case "{resource_name}":\n            return Uint8List.fromList([{content}]);\n'

def output_dart(output_path, resources, binary_files):
    output_content = f'// {os.path.basename(output_path).split(".")[0]}\n\n'
    output_content += "import 'dart:typed_data';\n"
    output_content += 'String load_resource(String resource_name) {\n'
    output_content += '    switch (resource_name) {\n'

    for resource in resources:
        resource_name, file_path = resource.split(',')
        output_content += generate_dart_source(file_path, resource_name)

    output_content += '        default:\n'
    output_content += '            print("resource not found: ${resource_name}");\n'
    output_content += '            return "";\n'
    output_content += '    }\n'
    output_content += '}\n'

    # binary data
    output_content += '\n\n'
    output_content += 'Uint8List load_binary(String resource_name) {\n'
    output_content += '    switch (resource_name) {\n'

    for resource in binary_files:
        resource_name, file_path = resource.split(',')
        output_content += generate_dart_source_for_binary(file_path, resource_name)

    output_content += '        default:\n'
    output_content += '            print("resource not found: ${resource_name}");\n'
    output_content += '            return Uint8List.fromList([]);\n'
    output_content += '    }\n'
    output_content += '}\n'

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(output_content)

# Main ---------------------------------------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description='Generate Erlang source code from text files.')
    parser.add_argument('--resource', action='append', required=False, default=[],help='Resource name and file path, separated by a comma.')
    parser.add_argument('--binary', action='append', required=False, default=[],help='Resource name and file path, separated by a comma.')
    parser.add_argument('--output-erl', default="", required=False, help='Path to output the Erlang source code.')
    parser.add_argument('--output-js', default="", required=False, help='Path to output the Javascript source code.')
    parser.add_argument('--output-dart', default="", required=False, help='Path to output the Dart source code.')

    args = parser.parse_args()
    output_path_erl = args.output_erl
    output_path_js = args.output_js
    output_path_dart = args.output_dart
    resources = args.resource
    binary_files = args.binary

    if output_path_erl != "":
        output_erl(output_path_erl, resources)
    
    if output_path_js != "":
        output_js(output_path_js, resources)

    if output_path_dart != "":
        output_dart(output_path_dart, resources, binary_files)


if __name__ == '__main__':
    main()
