export default function Button (props) {  
  const baseClasses = "w-12 h-12 flex items-center justify-center text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-full border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-100 dark:text-white dark:bg-gray-800 dark:border-gray-600 dark:hover:bg-gray-700 dark:hover:text-white dark:focus:ring-gray-700";

  const finalClasses = props.customClass ? `${baseClasses} ${props.customClass}` : baseClasses;
  
  return (
    <div 
      class={finalClasses}
      style={props.customStyle}
      onClick={props.onClick}
      onDoubleClick={props.onDoubleClick}
    >
      {props.children}
    </div>
  )
}