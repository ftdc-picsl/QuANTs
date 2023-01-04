import itk
import SimpleITK as sitk
import ants
import numpy as np

def itk_2_ants(itk_img):
    """Convert an itk image to an ants image."""
    arr = itk.GetArrayFromImage(itk_img)
    arr = np.swapaxes(arr, 0, 2)
    ants_img = ants.from_numpy(arr)
    ants_img.set_spacing(tuple(itk_img.GetSpacing()))
    ants_img.set_origin(tuple(itk_img.GetOrigin()))
    ants_img.set_direction(itk.array_from_matrix(itk_img.GetDirection()))
    return ants_img

def ants_2_itk(ants_img):
    """Convert an ants image to an itk image."""
    arr = ants_img.numpy()
    arr = np.swapaxes(arr, 0, 2)
    arr = np.squeeze(arr)
    itk_img = itk.GetImageFromArray(arr)
    itk_img.SetSpacing(ants_img.spacing)
    itk_img.SetOrigin(ants_img.origin)
    itk_img.SetDirection(itk.matrix_from_array(ants_img.direction))
    return itk_img

def sitk_2_ants(sitk_img):
    """Convert a simple itk image to an ants image."""
    arr = sitk.GetArrayFromImage(sitk_img)
    arr = np.swapaxes(arr, 0, 2)
    ants_img = ants.from_numpy(arr)
    ants_img.set_spacing(tuple(sitk_img.GetSpacing()))
    ants_img.set_origin(tuple(sitk_img.GetOrigin()))
    dim = sitk_img.GetDimension()
    dArr = np.asarray(sitk_img.GetDirection())
    dArr.shape = (dim, dim)
    ants_img.set_direction(dArr)
    return ants_img

def ants_2_sitk(ants_img):
    """Convert an ants image to a simple itk image."""
    arr = ants_img.numpy()
    arr = np.swapaxes(arr, 0, 2)
    arr = np.squeeze(arr)
    sitk_img = sitk.GetImageFromArray(arr)
    sitk_img.SetSpacing(ants_img.spacing)
    sitk_img.SetOrigin(ants_img.origin)
    sitk_img.SetDirection(ants_img.direction.flatten())
    # ?? sitk_img.SetDirection(ants_img.direction.flatten('F'))
    return sitk_img